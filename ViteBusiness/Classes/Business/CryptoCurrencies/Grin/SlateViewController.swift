//
//  ShareSlateViewController.swift
//  Pods
//
//  Created by haoshenyang on 2019/3/12.
//

import UIKit
import Vite_GrinWallet
import ViteWallet
import BigInt

class SlateViewController: UIViewController {

    enum OperateType: Int {
        case sent
        case receive
        case finalize
    }

    @IBOutlet weak var titleView: GrinTransactionTitleView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var slateIdLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var operateButton: UIButton!
    @IBOutlet weak var slateIDLabel: UILabel!

    var opendSlate: Slate?
    var opendSlateUrl: URL?

    var type = OperateType.sent
    var document: UIDocumentInteractionController!

    let transferVM = GrinTransactVM()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        bind()
    }

    func setUpView() {

        titleView.tokenIconView.tokenInfo = GrinManager.tokenInfo
        titleView.symbolLabel.text = [
            R.string.localizable.grinSentTitle(),
            R.string.localizable.grinReceiveTitle(),
            R.string.localizable.grinFinalizeTitle()
            ][type.rawValue]

        descriptionLabel.text = [
            R.string.localizable.grinShareFileDesc(),
            R.string.localizable.grinShareFileDesc(),
            R.string.localizable.grinFinalizeDesc(),
        ][type.rawValue]

        slateIdLabel.text = opendSlate?.id
        tableView.reloadData()

        let title =  [R.string.localizable.grinShareFile(),
                      R.string.localizable.grinSignAndShare(),
                      R.string.localizable.grinFinalize()][type.rawValue]
        operateButton.setTitle(title, for: .normal)

        statusImageView.image = [
            R.image.grin_tx_file_init(),
            R.image.grin_tx_file_receive(),
            R.image.grin_tx_file_finalize()
            ][type.rawValue]

        statusLabel.text = [
            R.string.localizable.grinTxFileInitStatus(),
            R.string.localizable.grinTxTypeSent(),
            R.string.localizable.grinTxTypeReceived(),
        ][type.rawValue]

        slateIDLabel.text = R.string.localizable.grinTxidTitle()
    }

    func bind() {

        transferVM.receiveSlateCreated.asObserver()
            .bind { [weak self] (slate,url) in
                self?.shareSlate(url: url)
        }

        transferVM.message.asObservable()
            .bind { message in
                Toast.show(message)
        }

    }

    @IBAction func handleSlate(_ sender: Any) {
        guard let slate = opendSlate ,let url = opendSlateUrl else { return }
        if type == .sent {
            shareSlate(url: url)
        } else if type == .receive {
            transferVM.action.onNext(.receiveTx(slateUrl: url))
        } else if type == .finalize {
            transferVM.action.onNext(.finalizeTx(slateUrl: url))
        }
    }

    func shareSlate(url: URL) {
        document = UIDocumentInteractionController(url: url)
        document.presentOpenInMenu(from: self.view.bounds, in: self.view, animated: true)
    }

}

extension SlateViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.textLabel?.textColor = UIColor(netHex: 0x3e4159)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = UIColor(netHex: 0x3e4159)
        guard let slate = opendSlate else { fatalError() }
        var arr = [
            (R.string.localizable.grinSentAmount(), Balance(value: BigInt(slate.amount)).amount(decimals: 9, count: 9) + " GRIN") ,
            (R.string.localizable.grinSentFee(), Balance(value: BigInt(slate.fee)).amount(decimals: 9, count: 9) + " GRIN")
        ]
        cell.textLabel?.text = arr[indexPath.row].0
        cell.detailTextLabel?.text = arr[indexPath.row].1
        return cell
    }
}