//
//  SendGrinViewController.swift
//  Action
//
//  Created by haoshenyang on 2019/3/11.
//

import UIKit
import Vite_GrinWallet
import RxSwift
import RxCocoa
import BigInt
import ViteWallet


class SendGrinViewController: UIViewController {

    @IBOutlet weak var titleView: GrinTransactionTitleView!
    @IBOutlet weak var spendableLabel: UILabel!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var amountConstraint: NSLayoutConstraint!
    @IBOutlet weak var balanceBackground: UIImageView!
    @IBOutlet weak var transactButton: UIButton!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var spendableTitleLabel: UILabel!
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var amountTitleLabel: UILabel!
    @IBOutlet weak var feeTitleLable: UILabel!

    var transferMethod = TransferMethod.file
    let transferVM = GrinTransactVM()
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        kas_activateAutoScrollingForView(view)
    }

    func bind() {
        GrinManager.default.balanceDriver.drive(onNext: { [weak self] (balance) in
            self?.spendableLabel.text = balance.amountCurrentlySpendable
        })
        .disposed(by: rx.disposeBag)
        GrinManager.default.getBalance()

        amountTextField.rx.text
            .distinctUntilChanged()
            .throttle(1.5, scheduler: MainScheduler.instance)
            .map { GrinTransactVM.Action.inputTx(amount: $0)}
            .bind(to: transferVM.action)
            .disposed(by: rx.disposeBag)

        transferVM.txFee.asObservable()
            .bind(to: feeLabel.rx.text)
            .disposed(by: rx.disposeBag)

        transferVM.sendSlateCreated.asObserver()
            .bind { [weak self] (slate, url) in
                var fullInfo = GrinFullTxInfo()
                var txs: [TxLogEntry] = []
                do {
                    let (_ ,logeEntrys) = try GrinManager.default.txsGet(refreshFromNode: false).dematerialize()
                    txs = logeEntrys
                } catch {

                }
                let localInfo = GrinLocalInfoService.shared.getSendInfo(slateId: slate.id)
                fullInfo.localInfo = localInfo
                fullInfo.txLogEntry = txs.filter({ (tx) -> Bool in
                    tx.txSlateId == slate.id && ( tx.txType == .txSent || tx.txType == .txSentCancelled)
                }).last

                fullInfo.openedSalteUrl = url
                let vc = GrinTxDetailViewController()
                vc.fullInfo = fullInfo

                var viewControllers = self?.navigationController?.viewControllers
                viewControllers?.popLast()
                viewControllers?.append(vc)
                if let viewControllers = viewControllers {
                    self?.navigationController?.setViewControllers(viewControllers, animated: true)
                }
            }
            .disposed(by: rx.disposeBag)

        transferVM.message.asObservable()
            .bind { [weak self] message in
                Toast.show(message)
            }
            .disposed(by: rx.disposeBag)


        transferVM.sendTxSuccess.asObserver()
            .delay(2, scheduler: MainScheduler.instance)
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: rx.disposeBag)

        transferVM.sendButtonEnabled.asObservable()
            .bind { [weak self] in
                self?.transactButton.isEnabled = $0
            }
            .disposed(by: rx.disposeBag)

    }

    func setUpView()  {
        titleView.symbolLabel.text = R.string.localizable.grinSentTitle()
        titleView.tokenIconView.tokenInfo = GrinManager.tokenInfo
        spendableTitleLabel.text = R.string.localizable.grinBalanceSpendable()
        addressTitleLabel.text = R.string.localizable.confirmTransactionAddressTitle()
        amountTitleLabel.text = R.string.localizable.grinSentAmount()
        feeTitleLable.text = R.string.localizable.grinSentFee()

        view.backgroundColor = UIColor.init(netHex: 0xffffff)
        balanceBackground.backgroundColor = UIColor.init(netHex: 0xffffff)
        balanceBackground.layer.shadowColor = UIColor(netHex: 0x000000).cgColor
        balanceBackground.layer.shadowOpacity = 0.1
        balanceBackground.layer.shadowOffset = CGSize(width: 0, height: 0)
        balanceBackground.layer.shadowRadius = 4

        let leftView = UIView()
        leftView.layer.cornerRadius = 2
        leftView.layer.masksToBounds = true
        leftView.backgroundColor = UIColor.init(netHex: 0x759BFA)
        balanceBackground.addSubview(leftView)
        leftView.snp.makeConstraints { (m) in
            m.top.left.bottom.equalToSuperview()
            m.width.equalTo(6)
        }

        let rightView = UIView()
        rightView.backgroundColor = UIColor.init(netHex: 0xffffff)
        leftView.addSubview(rightView)
        rightView.snp.makeConstraints { (m) in
            m.top.right.bottom.equalToSuperview()
            m.width.equalTo(3)
        }
        amountTextField.delegate = self

        if self.transferMethod == .file {
            amountConstraint.constant = 10
            self.view.layoutIfNeeded()
            transactButton.setTitle(R.string.localizable.grinSentCreatFile(), for: .normal)
        } else {
            transactButton.setTitle(R.string.localizable.grinSentNext(), for: .normal)
        }
    }

    @IBAction func sendAction(_ sender: Any) {
        guard let amountString = amountTextField.text else { return }
        guard (transferMethod == .file || !(addressTextField.text?.isEmpty ?? true)) else { return }


        if transferMethod == .http {
            Statistics.log(eventId: "Vite_app_wallet_TransferGrin_HTTP_2", attributes: ["uuid": UUID.stored])
        } else if transferMethod == .vite {
            Statistics.log(eventId: "Vite_app_wallet_TransferGrin_VITE_2", attributes: ["uuid": UUID.stored])

        } else if transferMethod == .file {
            Statistics.log(eventId: "Vite_app_wallet_TransferGrin_File_2", attributes: ["uuid": UUID.stored])
        }


        var send = {
            self.view.displayLoading()
            self.transferVM.txStrategies(amountString: self.amountTextField.text) { [weak self] (fee) in
                self?.view.hideLoading()
                guard let fee = fee,
                    !fee.isEmpty else { return }
                let confirmType = ConfirmGrinTransactionViewModel(amountString: amountString, feeString: fee, confirmTitle: R.string.localizable.grinPayTitleCreat())
                Workflow.confirmWorkflow(viewModel: confirmType, confirmSuccess: {
                    if self?.transferMethod == .http {
                        Statistics.log(eventId: "Vite_app_wallet_TransferGrin_HTTP_3", attributes: ["uuid": UUID.stored])
                    } else if self?.transferMethod == .vite {
                        Statistics.log(eventId: "Vite_app_wallet_TransferGrin_VITE_3", attributes: ["uuid": UUID.stored])
                    } else if self?.transferMethod == .file {
                        
                    }

                    let amountString = self?.amountTextField.text
                    if self?.transferMethod == .file {
                        self?.transferVM.action.onNext(.creatTxFile(amount: amountString))
                    } else if let destnation = self?.addressTextField.text {
                        self?.transferVM.action.onNext(.sentTx(amountString: amountString, destnation: destnation))
                    }
                })
            }
        }

        if transferMethod != .file,
            let destination = self.addressTextField.text,
            destination.hasPrefix("http"),
            let viteAddress = destination.components(separatedBy: "/").last, viteAddress.isViteAddress {
            Alert.show(into: self, title: R.string.localizable.grinSentSuggestUseViteTitle(), message: R.string.localizable.grinSentSuggestUseViteDesc(), actions: [
                (.default(title: R.string.localizable.grinSentStillUseHttp()), { _ in
                    send()
                }),
                (.default(title: R.string.localizable.grinSentSwitch()), { _ in
                    self.addressTextField.text = viteAddress
                    send()
                }),])
        } else {
            send()
        }

    }

    @IBAction func selectAddress(_ sender: Any) {
        FloatButtonsView(targetView: self.addressButton, delegate: self, titles:
            [R.string.localizable.grinSendPageViteContactsButtonTitle(),
             R.string.localizable.sendPageScanAddressButtonTitle()]).show()
    }
}

extension SendGrinViewController: FloatButtonsViewDelegate {

    func didClick(at index: Int) {
        if index == 0 {
            let viewModel = AddressListViewModel.createAddressListViewModel(for: CoinType.grin)
            let vc = AddressListViewController(viewModel: viewModel)
            vc.selectAddressDrive.drive(addressTextField.rx.text).disposed(by: rx.disposeBag)
            UIViewController.current?.navigationController?.pushViewController(vc, animated: true)
        } else if index == 1 {
            let scanViewController = ScanViewController()
            scanViewController.reactor = ScanViewReactor()
            _ = scanViewController.rx.result.bind {[weak self, scanViewController] result in
                if case .success(let uri) = ViteURI.parser(string: result) {
                    self?.addressTextField.text = uri.address
                } else {
                    self?.addressTextField.text = result
                }
                scanViewController.navigationController?.popViewController(animated: true)
            }
            UIViewController.current?.navigationController?.pushViewController(scanViewController, animated: true)
        }
    }
}

extension SendGrinViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == amountTextField {
            let (ret, text) = InputLimitsHelper.allowDecimalPointWithDigitalText(textField.text ?? "", shouldChangeCharactersIn: range, replacementString: string, decimals: 9)
            textField.text = text
            return ret
        } else {
            return true
        }
    }
}

