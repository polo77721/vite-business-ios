//
//  ViewInfoView.swift
//  Vite
//
//  Created by Water on 2018/11/6.
//  Copyright © 2018年 vite labs. All rights reserved.
//

enum VoteStatus: Int {
    case noVote = 0
    case voteSuccess = 1
    case voting = 2
    case cancelVoting = 3
    case cancelVoteSuccess = 4
    case voteInvalid = 5

    var display: String {
        switch self {
        case .noVote:
            return ""
        case .voteSuccess:
            return R.string.localizable.votePageVoteStatusVoteSuccess()
        case .voting:
            return R.string.localizable.votePageVoteStatusVoting()
        case .cancelVoting:
             return R.string.localizable.votePageVoteStatusCancelVoting()
        case .cancelVoteSuccess:
            return ""
        case .voteInvalid:
            return R.string.localizable.votePageVoteStatusVoteInvalid()
        }
    }
}
class VoteInfoView: UIView {
    lazy var bgView: VoteInfoBgView = {
        let bgView = VoteInfoBgView()
        bgView.iconImg.isHidden = true
        return bgView
    }()

    lazy var nodeNameLab: UILabel = {
        let nodeNameLab = UILabel()
        nodeNameLab.textAlignment = .left
        nodeNameLab.font = Fonts.Font16_b
        nodeNameLab.textColor  = .white
        return nodeNameLab
    }()

    lazy var nodeStatusLab: LabelTipView = {
        let nodeStatusLab = LabelTipView("")
        nodeStatusLab.titleLab.textAlignment = .left
        nodeStatusLab.titleLab.font = Fonts.Font14_b
        nodeStatusLab.titleLab.textColor  = .white
        nodeStatusLab.tipButton.setImage(R.image.icon_button_infor()?.tintColor(.white).resizable, for: .normal)
        nodeStatusLab.tipButton.setImage(R.image.icon_button_infor()?.tintColor(.white).resizable, for: .highlighted)
        nodeStatusLab.tipButton.isHidden = true
        return nodeStatusLab
    }()

    lazy var nodePollsTitleLab: IconLabelView = {
        let nodePollsTitleLab = IconLabelView(R.string.localizable.votePageVoteInfoNodePollsTitle())
        nodePollsTitleLab.titleLab.textAlignment = .left
        nodePollsTitleLab.titleLab.font = Fonts.Font14
        nodePollsTitleLab.titleLab.textColor  = .white
        nodePollsTitleLab.tipImg.image = R.image.icon_votecount()
        return nodePollsTitleLab
    }()

    lazy var nodePollsLab: UILabel = {
        let nodePollsLab = UILabel()
        nodePollsLab.textAlignment = .left
        nodePollsLab.font = Fonts.Font16_b
        nodePollsLab.textColor  = .white
        nodePollsLab.adjustsFontSizeToFitWidth = true
        return nodePollsLab
    }()

    lazy var voteStatusLab: LabelBgView = {
        let voteStatusLab = LabelBgView()
        voteStatusLab.titleLab.textAlignment = .center
        voteStatusLab.titleLab.font = Fonts.Font12
        voteStatusLab.titleLab.textColor  = .white
        return voteStatusLab
    }()

    lazy var operationBtn: UIButton = {
        let operationBtn = UIButton()
        operationBtn.setTitleColor(UIColor.white, for: .normal)
        operationBtn.setTitleColor(UIColor.white, for: .highlighted)
        operationBtn.setTitleColor(UIColor(netHex: 0xECECEC), for: .disabled)
        operationBtn.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0x3460CE)).resizable, for: .normal)
        operationBtn.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0x3460CE)).resizable, for: .highlighted)
        operationBtn.setBackgroundImage(R.image.background_button_blue()?.tintColor(UIColor(netHex: 0xBCC0CA)).resizable, for: .disabled)
             operationBtn.titleLabel?.font = Fonts.Font14_b
        operationBtn.setTitle(R.string.localizable.submitCancel(), for: .normal)
        operationBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        operationBtn.titleLabel?.adjustsFontSizeToFitWidth  = true
        operationBtn.layer.cornerRadius = 12
        operationBtn.layer.masksToBounds = true
        return operationBtn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white

        self._addViewConstraint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var voteInfo: VoteInfo?
    var voteStatus: VoteStatus?

    func changeInfoCancelVoting() {
        self.voteStatus = .cancelVoting
        voteStatusLab.titleLab.text = self.voteStatus?.display
        voteStatusLab.bgImg.image = R.image.btn_path_bg()?.tintColor(UIColor(netHex: 0x0046FF)).resizable
        operationBtn.isEnabled = false
    }
    func resetView() {
        self.voteInfo = nil
        self.voteStatus = .noVote
    }

    func reloadData(_ voteInfo: VoteInfo, _ voteStatus: VoteStatus?) {
        self.voteInfo = voteInfo
        self.voteStatus = voteStatus

        nodeNameLab.text = voteInfo.nodeName
        nodeStatusLab.titleLab.text = voteInfo.nodeStatus?.display

        nodePollsLab.text =  voteInfo.balance?.amountShort(decimals: TokenCacheService.instance.viteToken.decimals)
        voteStatusLab.titleLab.text = voteStatus?.display

        if  voteInfo.nodeStatus == .valid {
            nodeStatusLab.tipButton.isHidden = true
        } else {
            nodeStatusLab.tipButton.isHidden = false
        }

        if  voteStatus == .voting || voteStatus == .cancelVoting {
            voteStatusLab.bgImg.image = R.image.btn_path_bg()?.tintColor(UIColor(netHex: 0x0046FF)).resizable
            operationBtn.isEnabled = false
        } else if voteStatus == .voteSuccess || voteStatus == .cancelVoteSuccess {
                voteStatusLab.bgImg.image = R.image.btn_path_bg()?.tintColor(UIColor(netHex: 0xFEC102)).resizable
                operationBtn.isEnabled = true
            } else if voteStatus == .voteInvalid {
                voteStatusLab.bgImg.image = R.image.btn_path_bg()?.tintColor(UIColor(netHex: 0x99A4C1)).resizable
                operationBtn.isEnabled = true
            }
    }

    private func _addViewConstraint() {
        self.addSubview(bgView)
        bgView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }

        self.addSubview(nodeNameLab)
        self.addSubview(nodeStatusLab)
        self.addSubview(nodePollsTitleLab)
        self.addSubview(nodePollsLab)
        self.addSubview(voteStatusLab)
        self.addSubview(operationBtn)

        nodeStatusLab.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(14)
            make.left.equalTo(self).offset(14)
            make.height.equalTo(20)
        }

        voteStatusLab.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(14)
            make.right.equalTo(self).offset(-14)
            make.height.equalTo(20)
        }

        nodeNameLab.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(61)
            make.left.equalTo(self).offset(14)
            make.right.equalTo(self).offset(-14)
            make.height.equalTo(20)
        }

        nodePollsTitleLab.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.snp.bottom).offset(-16)
            make.left.equalTo(self).offset(14)
            make.height.equalTo(20)
        }
        nodePollsLab.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(nodePollsTitleLab)
            make.left.equalTo(nodePollsTitleLab.snp.right).offset(10)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(operationBtn.snp.left).offset(-10)
        }
        operationBtn.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(nodePollsTitleLab)
            make.right.equalTo(self).offset(-14)
            make.height.equalTo(25)
        }
    }
}
