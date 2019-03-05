//
//  WalletHomeBalanceInfoViewModel.swift
//  Vite
//
//  Created by Stone on 2018/9/9.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import Foundation
import ViteWallet
import RxSwift
import RxCocoa

final class WalletHomeBalanceInfoViewModel {

    let tokenInfo: TokenInfo
    let icon: URL
    let symbol: String
    let coinFamily: String
    let balance: String
    let price: String

    init(balanceInfo: WalletHomeBalanceInfo) {
        self.tokenInfo = balanceInfo.tokenInfo
        self.icon = URL(string: tokenInfo.icon)!
        self.symbol = tokenInfo.symbol
        self.coinFamily = tokenInfo.coinFamily
        self.balance = balanceInfo.balance.amountShort(decimals: tokenInfo.decimals)
        self.price = "≈" + ExchangeRateManager.instance.rateMap.priceString(for: balanceInfo.tokenInfo, balance: balanceInfo.balance)
    }
}
