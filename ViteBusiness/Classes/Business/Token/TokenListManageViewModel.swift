//
//  TokenListManageViewModel.swift
//  ViteBusiness
//
//  Created by Water on 2019/2/22.
//

import Foundation
import RxSwift
import RxCocoa

public typealias TokenListArray = [[TokenInfo]]

final class TokenListManageViewModel {
    var newAssetTokens : [TokenInfo] = []
    func isHasNewAssetTokens() -> Bool {
        return self.newAssetTokens.count > 0 ? true : false
    }

    lazy var tokenListRefreshDriver = self.tokenListRefreshRelay.asDriver()
    fileprivate  var tokenListRefreshRelay = BehaviorRelay<TokenListArray>(value: TokenListArray())

    init(_ newAssetTokens: [TokenInfo]) {
        self.newAssetTokens = newAssetTokens
    }

    func refreshList() {
        TokenListService.instance.fetchTokenListCacheData()
        self.mergeData()
    }

    func mergeData() {
        var localData = MyTokenInfosService.instance.tokenInfos
        let map = TokenListService.instance.tokenListMap
        var defaultList = [TokenInfo]()
        //make map in a line list
        for item in map {
            defaultList.append(contentsOf: item.value)
        }

        //remove
        for server in defaultList {
            for (index,local) in localData.enumerated() {
                if local.tokenCode == server.tokenCode {
                    localData.remove(at: index)
                }
            }
        }

        var localViteToken = [TokenInfo]()
        var localEthToken = [TokenInfo]()
        var localGrinToken = [TokenInfo]()
        for item in localData {
            if item.coinType == .vite {
                localViteToken.append(item)
            }else if item.coinType == .eth {
                localEthToken.append(item)
            } else if item.coinType == .grin {
                localGrinToken.append(item)
            }
        }

        var list = Array<[TokenInfo]>()

        if self.isHasNewAssetTokens() {
            list.append(self.newAssetTokens)
        }

        if var vite = map["VITE"] {
            vite.append(contentsOf: localViteToken)
            list.append(vite)
        }else {
            list.append(localViteToken)
        }
        if var eth = map["ETH"] {
            eth.append(contentsOf: localEthToken)
            list.append(eth)
        }else {
            list.append(localEthToken)
        }
        if var grin = map["GRIN"] {
            grin.append(contentsOf: localGrinToken)
            list.append(grin)
        }else {
            list.append(localGrinToken)
        }

        tokenListRefreshRelay.accept(list)
    }

}
