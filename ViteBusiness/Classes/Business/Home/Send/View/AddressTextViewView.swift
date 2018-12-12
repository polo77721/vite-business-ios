//
//  AddressTextViewView.swift
//  Vite
//
//  Created by Stone on 2018/10/25.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import ViteUtils

class AddressTextViewView: SendAddressViewType {

    fileprivate let addAddressButton = UIButton()
    fileprivate var floatView: AddAddressFloatView!

    let currentAddress: String?
    let placeholderStr: String?

    init(currentAddress: String? = nil, placeholder: String = "") {
        self.currentAddress = currentAddress
        self.placeholderStr = placeholder
        super.init(frame: CGRect.zero)

        self.placeholderLab.textColor = Colors.lineGray
        self.placeholderLab.font = AppStyle.descWord.font
        self.placeholderLab.text = placeholder

        titleLabel.text = R.string.localizable.sendPageToAddressTitle()
        textView.delegate = self
        addSubview(titleLabel)
        addSubview(textView)
        addSubview(placeholderLab)
        addSubview(addAddressButton)

        if let _ = currentAddress {
            addAddressButton.setImage(R.image.icon_button_address_add(), for: .normal)
            addAddressButton.setImage(R.image.icon_button_address_add()?.highlighted, for: .highlighted)
            addAddressButton.rx.tap.bind { [weak self] in
                guard let `self` = self else { return }
                if let old = self.floatView {
                    old.removeFromSuperview()
                }
                self.floatView = AddAddressFloatView(targetView: self.addAddressButton, delegate: self)
                self.floatView.show()
            }.disposed(by: rx.disposeBag)
        } else {
            addAddressButton.setImage(R.image.icon_button_address_scan(), for: .normal)
            addAddressButton.setImage(R.image.icon_button_address_scan()?.highlighted, for: .highlighted)
            addAddressButton.rx.tap.bind { [weak self] in
                self?.scanButtonDidClick()
            }.disposed(by: rx.disposeBag)
        }

        titleLabel.snp.makeConstraints { (m) in
            m.top.equalTo(self)
            m.left.equalTo(self)
            m.right.equalTo(self)
        }

        textView.snp.makeConstraints { (m) in
            m.top.equalTo(titleLabel.snp.bottom).offset(10)
            m.left.equalTo(titleLabel)
            m.right.equalTo(addAddressButton.snp.left).offset(-16)
            m.height.equalTo(55)
            m.bottom.equalTo(self)
        }

        placeholderLab.snp.makeConstraints { (m) in
            m.right.left.equalTo(textView)
            m.centerY.equalTo(addAddressButton)
        }

        addAddressButton.snp.makeConstraints { (m) in
            m.right.equalTo(titleLabel)
            m.bottom.equalTo(self).offset(-10)
        }

        textView.textColor = UIColor(netHex: 0x24272B)
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)

        let separatorLine = UIView()
        separatorLine.backgroundColor = Colors.lineGray
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints { (m) in
            m.height.equalTo(CGFloat.singleLineWidth)
            m.left.right.equalTo(titleLabel)
            m.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension AddressTextViewView: AddAddressFloatViewDelegate {

    func currentAddressButtonDidClick() {
        self.placeholderLab.text = ""
        textView.text = currentAddress
    }

    func scanButtonDidClick() {
        let scanViewController = ScanViewController()
        scanViewController.reactor = ScanViewReactor()
        _ = scanViewController.rx.result.bind {[weak self] result in
            switch result {
            case .viteURI(let uri):
                if case .transfer(let address, _, _, _, _ ) = uri {
                    self?.placeholderLab.text = ""
                    self?.textView.text = address.description
                }
            case .otherString:
                break
            }
        }
        self.ofViewController?.navigationController?.pushViewController(scanViewController, animated: true)
    }
}

extension AddressTextViewView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.placeholderLab.text = ""
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == nil || textView.text == "" {
            self.placeholderLab.text = self.placeholderStr
        } else {
            self.placeholderLab.text = ""
        }
    }
}
