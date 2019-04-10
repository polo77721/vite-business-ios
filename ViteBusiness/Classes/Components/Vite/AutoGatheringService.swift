//
//  AutoGatheringService.swift
//  Vite
//
//  Created by Stone on 2018/9/14.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import Foundation
import ViteWallet
import PromiseKit
import RxSwift
import RxCocoa
import Vite_HDWalletKit
import JSONRPCKit

import enum ViteWallet.Result

final class AutoGatheringService {
    static let instance = AutoGatheringService()
    private init() {}

    fileprivate let disposeBag = DisposeBag()
    fileprivate var service: ReceiveAllTransactionService?

    fileprivate var services: [ReceiveTransactionService] = []

    func start() {
        HDWalletManager.instance.accountsDriver.drive(onNext: { (accounts) in
            if accounts.isEmpty {
                self.service?.stopPoll()
                self.service = nil
                plog(level: .debug, log: "stop receive", tag: .transaction)
            } else {
                plog(level: .debug, log: "start receive for \(accounts.count) address", tag: .transaction)
                let service = ReceiveAllTransactionService(accounts: accounts, interval: 5, completion: { (r) in
                    switch r {
                    case .success(let ret):
                        for (send, _, account) in ret {
                            if let data = send.data {
                                let bytes = Bytes(data)
                                if bytes.count >= 2 && Bytes(bytes[0...1]) == Bytes(arrayLiteral: 0x80, 0x01) {
                                    let viteData = Data(bytes.dropFirst(2))
                                    GrinManager.default.handle(viteData: viteData, fromAddress: send.accountAddress?.description ?? "", account: account)
                                    let text = String(bytes: viteData, encoding: .utf8) ?? "parse failure"
                                    plog(level: .debug, log: "found grin data: \(text)", tag: .transaction)
                                }
                            }
                        }
                        plog(level: .debug, log: "success for receive \(ret.count) blocks", tag: .transaction)
                    case .failure(let error):
                        plog(level: .warning, log: "getOnroad for \(accounts.count) address error: \(error.viteErrorMessage)", tag: .transaction)
                    }
                })
                service.startPoll()
                self.service = service
            }
        }).disposed(by: disposeBag)
    }
}

extension AutoGatheringService {

    class ReceiveAllTransactionService: PollService {
        typealias Ret = Result<[(AccountBlock, AccountBlock, Wallet.Account)]>

        public let accounts: [Wallet.Account]
        public init(accounts: [Wallet.Account], interval: TimeInterval, completion: ((Ret) -> ())? = nil) {
            self.accounts = accounts
            self.interval = interval
            self.completion = completion
        }

        public var taskId: String = ""
        public var isPolling: Bool = false
        public var interval: TimeInterval = 0
        public var completion: ((Ret) -> ())?

        public func handle(completion: @escaping (Ret) -> ()) {
            let accounts = self.accounts

            type(of: self).getFirstOnroadIfHas(for: accounts)
                .map({ accountBlocks -> [(AccountBlock, Wallet.Account)] in
                    var ret: [(AccountBlock, Wallet.Account)] = []
                    let array = accountBlocks.compactMap { $0 }
                    for accountBlock in array {
                        for account in accounts where accountBlock.toAddress?.description == account.address.description {
                            ret.append((accountBlock, account))
                        }
                    }
                    return ret
                }).then({ pairs -> Promise<[(AccountBlock, AccountBlock, Wallet.Account)]> in
                    let promises = pairs.map { ret -> Promise<(AccountBlock, AccountBlock, Wallet.Account)?> in
                        return type(of: self).receive(onroadBlock: ret.0, account: ret.1)
                            .map({ (ret) -> (AccountBlock, AccountBlock, Wallet.Account)? in
                                return (ret.0, ret.1, ret.2)
                            })
                            // ignore error, and return nil
                            .recover({ (error) -> Promise<(AccountBlock, AccountBlock, Wallet.Account)?> in
                                plog(level: .warning, log: ret.1.address.description + " receive error: " + error.viteErrorMessage, tag: .transaction)
                                return .value(nil)
                            })
                    }
                    return when(fulfilled: promises)
                        // filter nil，make sure when promise success
                        .map({ (ret) -> [(AccountBlock, AccountBlock, Wallet.Account)] in
                            return ret.compactMap { $0 }
                        })
                }).done({ (ret) in
                    completion(Result(value: ret))
                }).catch({ (error) in
                    completion(Result(error: error))
                })
        }

        static func receive(onroadBlock: AccountBlock, account: Wallet.Account) -> Promise<(AccountBlock, AccountBlock, Wallet.Account)> {
            return ViteNode.rawTx.receive.withoutPow(account: account, onroadBlock: onroadBlock)
                .recover({ (e) -> Promise<AccountBlock> in
                    if ViteError.conversion(from: e).code == ViteErrorCode.rpcNotEnoughQuota {
                        return ViteNode.rawTx.receive.getPow(account: account, onroadBlock: onroadBlock)
                        .then({ context -> Promise<AccountBlock> in
                            return ViteNode.rawTx.receive.context(context)
                        })
                    } else {
                        return Promise(error: e)
                    }
                })
                .map({ (onroadBlock, $0, account) })
        }

        static func getFirstOnroadIfHas(for accounts: [Wallet.Account]) -> Promise<[AccountBlock?]> {
            let requests = accounts.map { GetOnroadBlocksRequest(address: $0.address.description, index: 0, count: 1) }
            return RPCRequest(for: Provider.default.server, batch: BatchFactory().create(requests)).promise
                .map { accountBlocksArray -> [AccountBlock?] in
                    return accountBlocksArray.map { $0.first }
            }
        }
    }
}
