//
//  GatewayTokenDetailViewController.swift
//  Action
//
//  Created by haoshenyang on 2019/6/11.
//

import UIKit
import Result
import SwiftyJSON

class GatewayTokenDetailViewController: BaseViewController {

    let tokenInfo: TokenInfo

    let tableView = UITableView.listView()

    var info = [String: Any]() {
        didSet {
            let tokenDigit = JSON(info)["tokenDigit"].int != nil ? String(JSON(info)["tokenDigit"].int!) : "--"

            var total: String? = "--"
            if let totalStr = JSON(info)["total"].string,
                let num = Double(totalStr),
                let tokenDigit  = JSON(info)["tokenDigit"].double {
                total = String(Int64(num) % Int64(pow(num, tokenDigit)))
            }
            var issueStr = "--"
            if let issue =  JSON(info)["states"]["issue"].int, issue == 1 {
                issueStr = R.string.localizable.crosschainTokenDetailIssuanceFalse()
            } else if let issue =  JSON(info)["states"]["issue"].int, issue == 2  {
                issueStr = R.string.localizable.crosschainTokenDetailIssuanceTrue()
            }
            var overview:String?  = "--"
            if LocalizationService.sharedInstance.currentLanguage == .chinese {
                overview = JSON(info)["overview"]["zh"].string
            } else {
                overview = JSON(info)["overview"]["en"].string
            }
            self.dateSource =
                [
                    (R.string.localizable.crosschainTokenDetailShortname(),JSON(info)["symbol"].string),
                    (R.string.localizable.crosschainTokenDetailId(),JSON(info)["platform"]["tokenAddress"].string),
                    (R.string.localizable.crosschainTokenDetailName(),JSON(info)["name"].string),
                    (R.string.localizable.crosschainTokenDetailAddress(),JSON(info)["publisher"].string ?? "--"),
                    (R.string.localizable.crosschainTokenDetailAmount(),total),
                    (R.string.localizable.crosschainTokenDetailDigit(),tokenDigit),
                    (R.string.localizable.crosschainTokenDetailIssuance(),issueStr),
                    (R.string.localizable.crosschainTokenDetailDate(),JSON(info)["updateTime"].string),
                    (R.string.localizable.crosschainTokenDetailDesc(),JSON(info)["overview"].string),
                ] as! [(String, String?)]
        }
    }

    var dateSource: [(String, String?)] = []

    init(tokenInfo: TokenInfo) {
        self.tokenInfo = tokenInfo
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let pageTitleView = PageTitleView.titleAndIcon(title: R.string.localizable.crosschainTokendetail(), icon: tokenInfo.chainIcon)
        pageTitleView.tokenInfo = tokenInfo
        navigationTitleView = pageTitleView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            m.left.right.bottom.equalToSuperview()
            m.top.equalTo(navigationTitleView!.snp.bottom)
        }
        tableView.delegate = self
        tableView.dataSource = self

        ExchangeProvider.instance.getTokenInfoDetail(tokenCode: tokenInfo.tokenCode) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.info = value
                self?.tableView.reloadData()
            case .failure(let e):
                Toast.show(e.localizedDescription)
            }
        }
    }

}

extension GatewayTokenDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dateSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.row == 8 {
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            cell.detailTextLabel?.numberOfLines = 0
        } else {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: nil)
        }

        if indexPath.row == 1 || indexPath.row == 3 {
            cell.detailTextLabel?.textColor = UIColor.init(netHex: 0x007AFF)
        } else {
            cell.detailTextLabel?.textColor = UIColor.init(netHex: 0x3E4A59, alpha:  0.7)
        }

        cell.textLabel?.font = font(16)
        cell.textLabel?.textColor = UIColor.init(netHex: 0x24272B)
        cell.textLabel?.text = self.dateSource[indexPath.row].0
        cell.detailTextLabel?.font = font(16)
        cell.detailTextLabel?.text = self.dateSource[indexPath.row].1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1  {
            var infoUrl = "\(ViteConst.instance.vite.explorer)/token/\(self.dateSource[indexPath.row].1 ?? "")"
            guard let url = URL(string: infoUrl) else { return }
            let vc = WKWebViewController.init(url: url)
            UIViewController.current?.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 3 {
            var infoUrl = "\(ViteConst.instance.vite.explorer)/account/\(self.dateSource[indexPath.row].1 ?? "")"
            guard let url = URL(string: infoUrl) else { return }
            let vc = WKWebViewController.init(url: url)
            UIViewController.current?.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 8 && self.dateSource[8].1 != nil {
            return UITableView.automaticDimension
        } else {
            return 54
        }
    }

}