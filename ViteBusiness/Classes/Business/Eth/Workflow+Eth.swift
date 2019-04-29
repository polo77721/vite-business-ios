//
//  Workflow+Eth.swift
//  Action
//
//  Created by Water on 2019/2/25.
//

import ViteEthereum
import Web3swift
import ViteWallet
import BigInt
import enum Alamofire.Result

public extension Workflow {
    static func sendEthTransactionWithConfirm(toAddress: String,
                                              tokenInfo: TokenInfo,
                                              amount: BigInt,
                                              gasPrice: Float,
                                              completion: @escaping (Result<String>) -> ()) {
        let sendBlock = {
            HUD.show()
            let g = BigInt(Web3.Utils.parseToBigUInt(String(gasPrice), units: .Gwei)!)
            if tokenInfo.isEtherCoin {
                EtherWallet.transaction.sendEther(to: toAddress, amount: amount, gasPrice: g, completion: { (result) in
                    HUD.hide()
                    switch result {
                    case .success(let txHash):
                        completion(Result.success(txHash))
                        AlertControl.showCompletion(R.string.localizable.sendPageToastSendTransferSuccess())
                    case .failure(let error):
                        completion(Result.failure(error))
                        break
                    }
                })

            } else {
                EtherWallet.transaction.sendToken(to: toAddress, amount: amount, gasPrice: g, contractAddress: tokenInfo.ethContractAddress, completion: { (result) in
                    HUD.hide()
                    switch result {
                    case .success(let txHash):
                        completion(Result.success(txHash))
                        AlertControl.showCompletion(R.string.localizable.sendPageToastSendTransferSuccess())
                    case .failure(let error):
                        completion(Result.failure(error))
                        break
                    }
                })
            }
        }

        //TODO::: no use block
        let block: (Result<AccountBlock>) -> () = { _ in

        }

        let amountString = "\(amount.amountFull(decimals: tokenInfo.decimals)) \(tokenInfo.symbol)"
        let gasLimit = tokenInfo.isEtherCoin ? EtherWallet.defaultGasLimitForEthTransfer: EtherWallet.defaultGasLimitForTokenTransfer
        let feeString = gasPrice.ethGasFeeDisplay(Float(gasLimit))

        let viewModel = ConfirmEthTransactionViewModel(tokenInfo: tokenInfo, addressString: toAddress, amountString: amountString, feeString: feeString)
        confirmWorkflow(viewModel: viewModel, completion: block, confirmSuccess: sendBlock)
    }
}
