//
//  SpotOperationView.swift
//  ViteBusiness
//
//  Created by Stone on 2020/3/30.
//

import Foundation
import RxSwift
import RxCocoa
import ViteWallet
import BigInt

class SpotOperationView: UIView {

    static let height: CGFloat = 303

    let segmentView = SegmentView()
    let priceTextField = TextFieldView()
    let priceLabel = UILabel().then {
        $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.45)
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.text = "≈--"
    }
    let volTextField = TextFieldView()
    let percentView = PercentView()

    let transferButton = UIButton().then {
        $0.setImage(R.image.icon_spot_transfer(), for: .normal)
        $0.setImage(R.image.icon_spot_transfer()?.highlighted, for: .highlighted)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 0)
    }

    let amountLabel = UILabel().then {
        $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.45)
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.text = R.string.localizable.spotPageAvailable("--")
    }

    let volLabel = UILabel().then {
        $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.45)
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.text = R.string.localizable.spotPageBuyable("--")
    }

    let vipButton = UIButton().then {
        $0.setTitleColor(UIColor(netHex: 0x007AFF), for: .normal)
        $0.setTitleColor(UIColor(netHex: 0x007AFF).highlighted, for: .highlighted)
        $0.setImage(R.image.icon_spot_vip_close(), for: .normal)
        $0.setImage(R.image.icon_spot_vip_close()?.highlighted, for: .highlighted)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.titleLabel?.adjustsFontSizeToFitWidth = true
        $0.transform = CGAffineTransform(scaleX: -1, y: 1)
        $0.titleLabel?.transform = CGAffineTransform(scaleX: -1, y: 1)
        $0.imageView?.transform = CGAffineTransform(scaleX: -1, y: 1)
        $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        $0.setTitle(R.string.localizable.spotPageOpenVip(), for: .normal)
    }

    let buyButton = UIButton().then {
        $0.setTitle(R.string.localizable.spotPageButtonBuyTitle(), for: .normal)
        $0.setTitleColor(UIColor.white, for: .normal)
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        $0.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0x01D764)).resizable, for: .normal)
        $0.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0x01D764)).highlighted.resizable, for: .highlighted)
    }
    let sellButton = UIButton().then {
        $0.setTitle(R.string.localizable.spotPageButtonSellTitle(), for: .normal)
        $0.setTitleColor(UIColor.white, for: .normal)
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        $0.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0xE5494D)).resizable, for: .normal)
        $0.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0xE5494D)).highlighted.resizable, for: .highlighted)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let limitBuyTitle = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            $0.textColor = UIColor(netHex: 0x3E4A59, alpha: 0.7)
            $0.text = R.string.localizable.spotPageButtonLimitBuyTitle()
        }


        priceTextField.textField.kas_setReturnAction(.resignFirstResponder, delegate: self)
        volTextField.textField.kas_setReturnAction(.resignFirstResponder, delegate: self)


        addSubview(segmentView)
        addSubview(limitBuyTitle)
        addSubview(priceTextField)
        addSubview(priceLabel)
        addSubview(volTextField)
        addSubview(percentView)
        addSubview(transferButton)
        addSubview(amountLabel)
        addSubview(volLabel)

        addSubview(vipButton)
        addSubview(buyButton)
        addSubview(sellButton)

        segmentView.snp.makeConstraints { (m) in
            m.top.left.right.equalToSuperview()

        }

        limitBuyTitle.snp.makeConstraints { (m) in
            m.top.equalTo(segmentView.snp.bottom).offset(12)
            m.left.equalToSuperview()
        }

        priceTextField.snp.makeConstraints { (m) in
            m.top.equalTo(limitBuyTitle.snp.bottom).offset(12)
            m.left.right.equalToSuperview()
        }

        priceLabel.snp.makeConstraints { (m) in
            m.top.equalTo(priceTextField.snp.bottom).offset(6)
            m.left.right.equalToSuperview()
        }

        volTextField.snp.makeConstraints { (m) in
            m.top.equalTo(priceLabel.snp.bottom).offset(6)
            m.left.right.equalToSuperview()
        }

        percentView.snp.makeConstraints { (m) in
            m.top.equalTo(volTextField.snp.bottom).offset(6)
            m.left.right.equalToSuperview()
        }

        transferButton.snp.makeConstraints { (m) in
            m.centerY.equalTo(amountLabel)
            m.right.equalTo(percentView)
            m.width.equalTo(37)
        }

        amountLabel.snp.makeConstraints { (m) in
            m.top.equalTo(percentView.snp.bottom).offset(12)
            m.left.equalToSuperview()
            m.right.equalTo(transferButton.snp.left)
        }

        volLabel.snp.makeConstraints { (m) in
            m.top.equalTo(amountLabel.snp.bottom).offset(4)
            m.left.right.equalToSuperview()
        }

        vipButton.snp.makeConstraints { (m) in
            m.top.equalTo(volLabel.snp.bottom).offset(4)
            m.left.equalToSuperview()
        }

        buyButton.snp.makeConstraints { (m) in
            m.top.equalTo(vipButton.snp.bottom).offset(12)
            m.left.right.equalToSuperview()
            m.bottom.equalToSuperview()
            m.height.equalTo(34)
        }

        sellButton.snp.makeConstraints { (m) in
            m.edges.equalTo(buyButton).priorityHigh()
        }

        segmentView.isBuyBehaviorRelay.bind { [weak self] isBuy in
            guard let `self` = self else { return }
            if isBuy {
                self.buyButton.isHidden = false
                self.sellButton.isHidden = true
                self.priceTextField.textField.placeholder = R.string.localizable.spotPagePriceBuyPlaceholder()
                self.volTextField.textField.placeholder = R.string.localizable.spotPageVolBuyPlaceholder()
            } else {
                self.buyButton.isHidden = true
                self.sellButton.isHidden = false
                self.priceTextField.textField.placeholder = R.string.localizable.spotPagePriceSellPlaceholder()
                self.volTextField.textField.placeholder = R.string.localizable.spotPageVolSellPlaceholder()
            }
            self.setPrice("")
            self.setVol("")
            self.percentView.index = nil
        }.disposed(by: rx.disposeBag)

        marketInfoBehaviorRelay.filterNil().bind { [weak self] info in
            TokenInfoCacheService.instance.tokenInfo(forViteTokenId: info.statistic.tradeToken) { [weak self] (ret) in
                if case .success(let tokenInfo) = ret {
                    self?.tradeToken.accept(tokenInfo)
                }
            }

            TokenInfoCacheService.instance.tokenInfo(forViteTokenId: info.statistic.quoteToken) { [weak self] (ret) in
                if case .success(let tokenInfo) = ret {
                    self?.quoteToken.accept(tokenInfo)
                }
            }
        }.disposed(by: rx.disposeBag)

        Driver.combineLatest(ViteBalanceInfoManager.instance.dexBalanceInfosDriver,
                             marketInfoBehaviorRelay.asDriver().filterNil(),
                             tradeToken.asDriver().filterNil(),
                             quoteToken.asDriver().filterNil(),
                             priceTextField.textField.rx.text.asDriver(),
                             segmentView.isBuyBehaviorRelay.asDriver()).drive(onNext: { [weak self] (balanceMap, info, tradeTokenInfo, quoteTokenInfo, priceText, isBuy) in
                                guard let `self` = self else { return }

                                let sourceTokenInfo = isBuy ? quoteTokenInfo : tradeTokenInfo
//                                let targetTokenInfo = isBuy ? tradeTokenInfo : quoteTokenInfo

                                let sourceToken = sourceTokenInfo.toViteToken()!
                                let balance = balanceMap[sourceToken.id]?.available ?? Amount()
                                self.amountLabel.text = R.string.localizable.spotPageAvailable(balance.amountFullWithGroupSeparator(decimals: sourceToken.decimals)) + " \(sourceTokenInfo.uniqueSymbol)"

                                if let text = priceText, let price = BigDecimal(text), price != BigDecimal(0) {
                                    self.priceLabel.text = "≈" + MarketInfoService.shared.legalPrice(quoteTokenSymbol: quoteTokenInfo.uniqueSymbol, price: text)
                                    if isBuy {
                                        let vol = BigDecimal(balance.amountFull(decimals: sourceToken.decimals))! / price
                                        self.volLabel.text = R.string.localizable.spotPageBuyable(BigDecimalFormatter.format(bigDecimal: vol, style: .decimalTruncation(Int(info.statistic.quantityPrecision)), padding: .none, options: [.groupSeparator])) + " \(tradeTokenInfo.uniqueSymbol)"
                                    } else {
                                        let vol = BigDecimal(balance.amountFull(decimals: sourceToken.decimals))! * price
                                        self.volLabel.text = R.string.localizable.spotPageSellable(BigDecimalFormatter.format(bigDecimal: vol, style: .decimalTruncation(Int(info.statistic.quantityPrecision)), padding: .none, options: [.groupSeparator])) + " \(quoteTokenInfo.uniqueSymbol)"
                                    }

                                } else {
                                    self.priceLabel.text = "≈--"
                                    if isBuy {
                                        self.volLabel.text = R.string.localizable.spotPageBuyable("--")
                                    } else {
                                        self.volLabel.text = R.string.localizable.spotPageSellable("--")
                                    }
                                }

        }).disposed(by: rx.disposeBag)


        Driver.combineLatest(priceTextField.textField.rx.text.asDriver(),
                             volTextField.textField.rx.text.asDriver()).drive(onNext: { [weak self] (_, _) in
                                guard let `self` = self else { return }
                                self.percentView.index = nil
        }).disposed(by: rx.disposeBag)

        percentView.changed = { [weak self] index in
            guard let `self` = self, let info = self.marketInfoBehaviorRelay.value else { return }

            guard let text = self.priceTextField.textField.text, let price = BigDecimal(text), price > BigDecimal(0) else {
                self.percentView.index = nil
                return
            }

            guard let quoteTokenInfo = self.quoteToken.value, let tradeTokenInfo = self.tradeToken.value else { return }

            let isBuy = self.segmentView.isBuyBehaviorRelay.value
            let sourceTokenInfo = isBuy ? quoteTokenInfo : tradeTokenInfo
//            let targetTokenInfo = isBuy ? tradeTokenInfo : quoteTokenInfo

            let sourceToken = sourceTokenInfo.toViteToken()!
            let balance = ViteBalanceInfoManager.instance.dexBalanceInfo(forViteTokenId: sourceToken.id)?.available ?? Amount()

            let vol: BigDecimal
            if isBuy {
                vol = BigDecimal(balance.amountFull(decimals: sourceToken.decimals))! / price
            } else {
                vol = BigDecimal(balance.amountFull(decimals: sourceToken.decimals))! * price
            }

            let percent = BigDecimal("\(PercentView.values[index])")!

            self.volTextField.textField.text = BigDecimalFormatter.format(bigDecimal: vol * percent, style: .decimalTruncation(Int(info.statistic.quantityPrecision)), padding: .none, options: [])
        }

        buyButton.rx.tap.bind { [weak self] in
            guard let `self` = self else { return }
            guard let tradeTokenInfo = self.tradeToken.value else { return }
            guard let quoteTokenInfo = self.quoteToken.value else { return }

            guard let priceText = self.priceTextField.textField.text, !priceText.isEmpty, let price = BigDecimal(priceText) else {
                Toast.show(R.string.localizable.spotPagePostToastPriceEmpty())
                return
            }

            guard let volText = self.volTextField.textField.text, !volText.isEmpty, let vol = volText.toAmount(decimals: tradeTokenInfo.decimals) else {
                Toast.show(R.string.localizable.spotPagePostToastVolEmpty())
                return
            }

            guard price > BigDecimal(0) else {
                Toast.show(R.string.localizable.spotPagePostToastPriceZero())
                return
            }

            guard vol > Amount(0) else {
                Toast.show(R.string.localizable.spotPagePostToastVolZero())
                return
            }

            let balance = ViteBalanceInfoManager.instance.dexBalanceInfo(forViteTokenId: quoteTokenInfo.viteTokenId)?.available ?? Amount()

            guard BigDecimal(balance * BigInt(10).power(tradeTokenInfo.decimals)) >= price * BigDecimal(vol * BigInt(10).power(quoteTokenInfo.decimals)) else {
                Toast.show(R.string.localizable.sendPageToastAmountError())
                return
            }

            Workflow.dexBuyWithConfirm(account: HDWalletManager.instance.account!,
                                       tradeTokenInfo: tradeTokenInfo,
                                       quoteTokenInfo: quoteTokenInfo,
                                       price: priceText,
                                       quantity: vol) { (r) in
                if case .success = r {

                }
            }
        }.disposed(by: rx.disposeBag)

        sellButton.rx.tap.bind { [weak self] in
            guard let `self` = self else { return }
            guard let tradeTokenInfo = self.tradeToken.value else { return }
            guard let quoteTokenInfo = self.quoteToken.value else { return }

            guard let priceText = self.priceTextField.textField.text, !priceText.isEmpty, let price = BigDecimal(priceText) else {
                Toast.show(R.string.localizable.spotPagePostToastPriceEmpty())
                return
            }

            guard let volText = self.volTextField.textField.text, !volText.isEmpty, let vol = volText.toAmount(decimals: tradeTokenInfo.decimals) else {
                Toast.show(R.string.localizable.spotPagePostToastVolEmpty())
                return
            }

            guard price != BigDecimal(0) else {
                Toast.show(R.string.localizable.spotPagePostToastPriceZero())
                return
            }

            guard vol != Amount(0) else {
                Toast.show(R.string.localizable.spotPagePostToastVolZero())
                return
            }

            let balance = ViteBalanceInfoManager.instance.dexBalanceInfo(forViteTokenId: tradeTokenInfo.viteTokenId)?.available ?? Amount()

            guard balance >= vol else {
                Toast.show(R.string.localizable.sendPageToastAmountError())
                return
            }

            Workflow.dexSellWithConfirm(account: HDWalletManager.instance.account!,
                                        tradeTokenInfo: tradeTokenInfo,
                                        quoteTokenInfo: quoteTokenInfo,
                                        price: priceText,
                                        quantity: vol) { (r) in
                if case .success = r {

                }
            }
        }.disposed(by: rx.disposeBag)
    }

    func setPrice(_ text: String) {
        priceTextField.textField.text = text
        priceTextField.textField.sendActions(for: .valueChanged)
    }

    func setVol(_ text: String) {
        volTextField.textField.text = text
        volTextField.textField.sendActions(for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let marketInfoBehaviorRelay: BehaviorRelay<MarketInfo?> = BehaviorRelay(value: nil)
    let tradeToken: BehaviorRelay<TokenInfo?> = BehaviorRelay(value: nil)
    let quoteToken: BehaviorRelay<TokenInfo?> = BehaviorRelay(value: nil)

    func bind(marketInfo: MarketInfo?) {
        marketInfoBehaviorRelay.accept(marketInfo)
        self.setPrice("")
        self.setVol("")
    }
}

extension SpotOperationView: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let info = marketInfoBehaviorRelay.value else {
            return false
        }

        if textField == priceTextField.textField {
            let (ret, text) = InputLimitsHelper.allowDecimalPointWithDigitalText(textField.text ?? "", shouldChangeCharactersIn: range, replacementString: string, decimals: Int(info.statistic.pricePrecision))
            textField.text = text
            return ret
        } else if textField == volTextField.textField {
            let (ret, text) = InputLimitsHelper.allowDecimalPointWithDigitalText(textField.text ?? "", shouldChangeCharactersIn: range, replacementString: string, decimals: Int(info.statistic.quantityPrecision))
            textField.text = text
            return ret
        } else {
            return true
        }
    }
}


extension SpotOperationView {

    class SegmentView: UIView {

        let buyButton = UIButton().then {
            $0.setTitle(R.string.localizable.spotPageButtonBuyTitle(), for: .normal)
            $0.layer.cornerRadius = 2
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            $0.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0x01D764)).resizable, for: .disabled)
            $0.setTitleColor(.white, for: .disabled)
            $0.setBackgroundImage(nil, for: .normal)
            $0.setTitleColor(UIColor(netHex: 0x3E4A59, alpha: 0.7), for: .normal)
        }

        let sellButton = UIButton().then {
            $0.setTitle(R.string.localizable.spotPageButtonSellTitle(), for: .normal)
            $0.layer.cornerRadius = 2
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            $0.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0xE5494D)).resizable, for: .disabled)
            $0.setTitleColor(.white, for: .disabled)
            $0.setBackgroundImage(nil, for: .normal)
            $0.setTitleColor(UIColor(netHex: 0x3E4A59, alpha: 0.7), for: .normal)
        }

        let isBuyBehaviorRelay: BehaviorRelay<Bool> = BehaviorRelay(value: true)

        override init(frame: CGRect) {
            super.init(frame: frame)

            layer.cornerRadius = 2
            backgroundColor = UIColor(netHex: 0xF3F5F9)

            addSubview(buyButton)
            addSubview(sellButton)

            buyButton.snp.makeConstraints { (m) in
                m.top.bottom.left.equalToSuperview()
                m.height.equalTo(30)
            }

            sellButton.snp.makeConstraints { (m) in
                m.top.bottom.right.equalToSuperview()
                m.left.equalTo(buyButton.snp.right)
                m.width.equalTo(buyButton)
            }

            isBuyBehaviorRelay.bind { [weak self] isBuy in
                guard let `self` = self else { return }
                self.buyButton.isEnabled = !isBuy
                self.sellButton.isEnabled = isBuy
            }.disposed(by: rx.disposeBag)

            buyButton.rx.tap.bind { [weak self] in
                self?.isBuyBehaviorRelay.accept(true)
            }.disposed(by: rx.disposeBag)

            sellButton.rx.tap.bind { [weak self] in
                self?.isBuyBehaviorRelay.accept(false)
            }.disposed(by: rx.disposeBag)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class TextFieldView: UIView {

        let textField = UITextField().then {
            $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            $0.keyboardType = .decimalPad
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            layer.cornerRadius = 2
            layer.borderColor = UIColor(netHex: 0xD3DFEF).cgColor
            layer.borderWidth = CGFloat.singleLineWidth

            addSubview(textField)

            textField.snp.makeConstraints { (m) in
                m.top.bottom.equalToSuperview()
                m.left.right.equalToSuperview().inset(10)
                m.height.equalTo(30)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class PercentView: UIView {

        static var values: [Double] = [
            0.25,
            0.5,
            0.75,
            1
        ]

        let buttons = PercentView.values.map {
            makeSegmentButton(title: String(format: "%.0f%", $0 * 100))
        }

        var changed: ((Int) -> Void)?

        var index: Int? = nil {
            didSet {
                self.updateState()
            }
        }


        override init(frame: CGRect) {
            super.init(frame: frame)

            for (index, button) in buttons.enumerated() {
                addSubview(button)
                button.snp.makeConstraints { (m) in
                    m.top.equalToSuperview()
                    m.bottom.equalToSuperview()
                    if index == 0 {
                        m.left.equalToSuperview()
                    } else {
                        m.left.equalTo(buttons[index - 1].snp.right).offset(4)
                        m.width.equalTo(buttons[index - 1])
                    }

                    if index == buttons.count - 1 {
                        m.right.equalToSuperview()
                    }
                }

                button.rx.tap.bind { [weak self] in
                    guard let `self` = self else { return }
                    self.index = index
                    self.changed?(index)
                }.disposed(by: rx.disposeBag)
            }
            updateState()
        }

        func updateState() {
            for (i, b) in self.buttons.enumerated() {
                b.isEnabled = (self.index != i)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        static func makeSegmentButton(title: String) -> UIButton {
            let ret = UIButton()
            ret.setTitle(title, for: .normal)
            ret.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            ret.setTitleColor(UIColor(netHex: 0x3E4A59, alpha: 0.45), for: .normal)
            ret.setTitleColor(UIColor(netHex: 0x007AFF), for: .disabled)
            ret.setBackgroundImage(R.image.icon_trading_segment_unselected_fram()?.resizable, for: .normal)
            ret.setBackgroundImage(R.image.icon_trading_segment_selected_fram()?.resizable, for: .disabled)
            return ret
        }
    }
}