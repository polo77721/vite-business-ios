//
//  MarketDetailInfoView.swift
//  ViteBusiness
//
//  Created by Stone on 2020/3/11.
//

import UIKit

class MarketDetailInfoView: UIView {

    let priceLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
    }

    let plegalPriceLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59)
    }

    let upDownImageView = UIImageView(image: R.image.icon_market_up())

    let percentLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    }

    let highTitleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.6)
        $0.text = R.string.localizable.marketDetailPageInfoHighTitle()
    }

    let lowTitleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.6)
        $0.text = R.string.localizable.marketDetailPageInfoLowTitle()
    }

    let quantityTitleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.6)
        $0.text = R.string.localizable.marketDetailPageInfoVolTitle()
    }


    let highLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59)
    }

    let lowLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59)
    }

    let quantityLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(netHex: 0x3E4A59)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(priceLabel)
        addSubview(plegalPriceLabel)
        addSubview(upDownImageView)
        addSubview(percentLabel)
        addSubview(highLabel)
        addSubview(lowLabel)
        addSubview(quantityLabel)

        addSubview(highTitleLabel)
        addSubview(lowTitleLabel)
        addSubview(quantityTitleLabel)

        priceLabel.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(6)
            m.left.equalToSuperview().offset(24)
        }

        plegalPriceLabel.snp.makeConstraints { (m) in
            m.top.equalTo(priceLabel.snp.bottom).offset(8)
            m.left.equalTo(priceLabel)
        }

        upDownImageView.snp.makeConstraints { (m) in
            m.centerY.equalTo(plegalPriceLabel)
            m.left.equalTo(plegalPriceLabel.snp.right).offset(8)
            m.size.equalTo(CGSize(width: 10, height: 10))
        }

        percentLabel.snp.makeConstraints { (m) in
            m.centerY.equalTo(plegalPriceLabel)
            m.left.equalTo(upDownImageView.snp.right)
        }

        highTitleLabel.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(6)
            m.right.equalToSuperview().offset(-80)
        }

        lowTitleLabel.snp.makeConstraints { (m) in
            m.top.equalTo(highTitleLabel.snp.bottom).offset(8)
            m.left.equalTo(highTitleLabel)
        }

        quantityTitleLabel.snp.makeConstraints { (m) in
            m.top.equalTo(lowTitleLabel.snp.bottom).offset(8)
            m.left.equalTo(lowTitleLabel)
        }

        highLabel.snp.makeConstraints { (m) in
            m.top.equalTo(highTitleLabel)
            m.left.equalTo(highTitleLabel.snp.right).offset(8)
        }

        lowLabel.snp.makeConstraints { (m) in
            m.top.equalTo(highLabel.snp.bottom).offset(8)
            m.left.equalTo(highLabel)
        }

        quantityLabel.snp.makeConstraints { (m) in
            m.top.equalTo(lowLabel.snp.bottom).offset(8)
            m.left.equalTo(lowLabel)
            m.bottom.equalToSuperview()
        }
    }

    func bind(marketInfo: MarketInfo) {
        priceLabel.text = marketInfo.statistic.closePrice
        plegalPriceLabel.text = "≈" + marketInfo.rate
        percentLabel.text = marketInfo.persentString
        upDownImageView.image = Double(marketInfo.statistic.priceChangePercent)! >= 0.0 ? R.image.icon_market_up() : R.image.icon_market_down()
        percentLabel.textColor = marketInfo.persentColor

        highLabel.text = marketInfo.statistic.highPrice
        lowLabel.text = marketInfo.statistic.lowPrice
        quantityLabel.text = marketInfo.statistic.quantity
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
