//
//  BalanceInfoDetailViteCoinAdapter.swift
//  ViteBusiness
//
//  Created by Stone on 2019/3/5.
//

import Foundation

class BalanceInfoDetailViteCoinAdapter: BalanceInfoDetailAdapter {

    func setup(containerView: UIView, tokenInfo: TokenInfo) {

        let cardView = BalanceInfoViteChainCardView()
        containerView.addSubview(cardView)
        cardView.snp.makeConstraints { (m) in
            m.top.equalToSuperview()
            m.left.equalToSuperview().offset(24)
            m.right.equalToSuperview().offset(-24)
            m.height.equalTo(188)
        }

        cardView.bind(tokenInfo: tokenInfo)

        let operationView = BalanceInfoViteCoinOperationView()
        containerView.addSubview(operationView)
        operationView.snp.makeConstraints { (m) in
            m.top.equalTo(cardView.snp.bottom).offset(16)
            m.left.equalToSuperview().offset(24)
            m.right.equalToSuperview().offset(-24)
            m.height.equalTo(44)
        }

        let transactionsView = BalanceInfoViteChainTransactionsView(tokenInfo: tokenInfo)
        containerView.addSubview(transactionsView)
        transactionsView.snp.makeConstraints { (m) in
            m.top.equalTo(operationView.snp.bottom).offset(14)
            m.left.equalToSuperview()
            m.right.equalToSuperview()
            m.bottom.equalToSuperview()
        }
    }
}