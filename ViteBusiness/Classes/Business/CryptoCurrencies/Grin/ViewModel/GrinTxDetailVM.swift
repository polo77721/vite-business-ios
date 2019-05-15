//
//  GrinTxDetailVM.swift
//  Action
//
//  Created by haoshenyang on 2019/5/9.
//

import Foundation
import Vite_GrinWallet
import BigInt
import ViteWallet
import SwiftyJSON
import RxSwift
import RxCocoa

class GrinTxDetailVM: NSObject {

    let txVM = GrinTransactVM()
    let infoVM = GrinWalletInfoVM()

    override init() {
        super.init()
        txVM.finalizeTxSuccess.asObserver()
            .bind { [weak self] _ in
                self?.updatePageInfo()
            }
            .disposed(by: rx.disposeBag)

        txVM.receiveSlateCreated.asObserver()
            .bind { [weak self] _ in
                self?.updatePageInfo()
            }
            .disposed(by: rx.disposeBag)


        infoVM.txCancelled.asObserver()
            .bind { [weak self] _ in
                self?.updatePageInfo()
            }
            .disposed(by: rx.disposeBag)
    }

    var fullInfo: GrinFullTxInfo = GrinFullTxInfo() {
        didSet {
            let pageInfo = self.creatGrinDetailPageInfo(fullInfo: fullInfo)
            self.pageInfo.accept(pageInfo)
        }
    }

    let pageInfo: BehaviorRelay<GrinDetailPageInfo> = BehaviorRelay(value: GrinDetailPageInfo())

    var blueLineImage: UIImage? {
        return R.image.grin_detail_line_blue()?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), resizingMode: .tile)
    }

    var grayLineImage: UIImage? {
        return R.image.grin_detail_line_gray()?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), resizingMode: .tile)
    }

    func creatGrinDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        if fullInfo.isSend {
            return self.creatSendGrinDetailPageInfo(fullInfo: fullInfo)
        } else if fullInfo.isReceive {
            return self.creatReceiveGrinDetailPageInfo(fullInfo: fullInfo)
        } else if fullInfo.txLogEntry?.txType == .confirmedCoinbase {
            return self.creatConfirmedCoinbaseDetailPageInfo(fullInfo: fullInfo)
        } else {
            return GrinDetailPageInfo()
        }
    }

    func creatSendGrinDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        if fullInfo.localInfo?.method == "Vite" {
            return self.creatSendGrinByViteDetailPageInfo(fullInfo: fullInfo)
        } else if fullInfo.localInfo?.method == "Http" {
            return self.creatSendGrinByHttpDetailPageInfo(fullInfo: fullInfo)
        } else if fullInfo.localInfo?.method == "File"  {
            return self.creatSendGrinByFileDetailPageInfo(fullInfo: fullInfo)
        } else {
            return self.creatSendGrinDetailPageInfoWithoutLocalInfo(fullInfo: fullInfo)
        }
    }

    func creatReceiveGrinDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        if fullInfo.isGatewayTx {
            return self.creatReceiveGrinByHttpDetailPageInfo(fullInfo: fullInfo)
        } else if fullInfo.isViteTx {
            return self.creatReceiveGrinByViteDetailPageInfo(fullInfo: fullInfo)
        } else if fullInfo.isFileTx {
            return self.creatReceiveGrinByFileDetailPageInfo(fullInfo: fullInfo)
        } else {
            return self.creatReceiveGrinDetailPageInfoWithoutAnyInfo(fullInfo: fullInfo)
        }
    }

    //MARK: - Done

    func creatSendGrinByViteDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        pageInfo.methodString = R.string.localizable.grinTxMethodVite()
        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        guard let localInfo = fullInfo.localInfo else { return pageInfo }
        guard let txInfo = fullInfo.txLogEntry  else { return pageInfo }

        //Details
        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = localInfo.slateId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusImage = R.image.grin_detail_created()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeSent(), attributes: nil)
        cellInfo1.timeStr = txInfo.timeString
        pageInfo.desc = R.string.localizable.grinDetailWaitHerOpenViteWalletToReceive()
        pageInfo.cellInfo.append(cellInfo1)

        let cancleTime = fullInfo.localInfo?.cancleSendTime ?? 0
        let getResponseFileTime = localInfo.getResponseFileTime ?? 0
        let finalizeTime = localInfo.finalizeTime ?? 0


        let cancleInfo = GrinDetailCellInfo()
        cancleInfo.statusImage = R.image.grin_detail_cancled_gray()
        cancleInfo.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
        cancleInfo.timeStr = cancleTime.grinTimeString()

        if txInfo.txType == .txSentCancelled && cancleTime > 0 && cancleTime < getResponseFileTime {
            pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
            cellInfo1.lineImage = grayLineImage
            pageInfo.cellInfo.append(cancleInfo)
            return pageInfo
        }

        let cellInfo2 = GrinDetailCellInfo()
        cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeWaitToFinalize(), attributes: nil)
        if let getResponseFileTime = localInfo.getResponseFileTime, getResponseFileTime > 0 {
            pageInfo.desc = R.string.localizable.grinDetailPleaseFinalize2()
            cellInfo1.lineImage = blueLineImage
            cellInfo2.statusImage = R.image.grin_detail_waitToSign()
            cellInfo2.timeStr = getResponseFileTime.grinTimeString()
        } else {
            cellInfo1.lineImage = grayLineImage
            cellInfo2.statusImage = R.image.grin_detail_waitToSign_gray()
        }
        pageInfo.cellInfo.append(cellInfo2)

        if txInfo.confirmed != true && txInfo.txType == .txSentCancelled && cancleTime > 0 && cancleTime > getResponseFileTime && cancleTime < finalizeTime {
            pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
            pageInfo.cellInfo.append(cancleInfo)
            cellInfo2.lineImage = grayLineImage
            return pageInfo
        }

        let cellInfo3 = GrinDetailCellInfo()
        cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeWaitToFinalize(), attributes: nil)
        if let finalizeTime = localInfo.finalizeTime, finalizeTime > 0 {
            pageInfo.desc = R.string.localizable.grinDetailTxisPostingPlsWait()
            cellInfo2.lineImage = blueLineImage
            cellInfo3.statusImage = R.image.grin_detail_poasting()
            cellInfo3.timeStr = localInfo.finalizeTime?.grinTimeString()
        } else {
            cellInfo2.lineImage = grayLineImage
            cellInfo3.statusImage = R.image.grin_detail_poasting_gray()
        }
        pageInfo.cellInfo.append(cellInfo3)

        let cellInfo4 = GrinDetailCellInfo()
        if fullInfo.txLogEntry?.confirmed == true {
            pageInfo.desc = R.string.localizable.grinDetailTxCompleted()
            cellInfo4.statusImage = R.image.grin_detail_confirmed()
            cellInfo3.lineImage = blueLineImage
            cellInfo4.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
        } else if  txInfo.txType == .txSentCancelled && cancleTime > 0 && cancleTime > getResponseFileTime && cancleTime > finalizeTime {
                pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
                let cancleInfo = GrinDetailCellInfo()
                cancleInfo.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
                cancleInfo.statusImage = R.image.grin_detail_cancled_gray()
                cellInfo3.lineImage = grayLineImage
                cancleInfo.timeStr = (cancleTime.grinTimeString())
                pageInfo.cellInfo.append(cancleInfo)
        }  else {
            cellInfo4.statusImage = R.image.grin_detail_confirmed_gray()
            cellInfo3.lineImage = grayLineImage
            cellInfo4.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
        }
        pageInfo.cellInfo.append(cellInfo4)

        if txInfo.confirmed != true && txInfo.txType != .txSentCancelled && cancleTime == 0  {
            let cancelAction = {
                self.infoVM.action.onNext(.cancel(txInfo))
                //self.updatePageInfo()
            }
            pageInfo.actions.append((R.string.localizable.cancel(), cancelAction))

        }
        return pageInfo
    }

    //MARK: - Done

    func creatSendGrinByHttpDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        let pageInfo = self.creatSendGrinByFileDetailPageInfo(fullInfo: fullInfo)
        pageInfo.title = R.string.localizable.grinSentTitle()
        pageInfo.methodString = R.string.localizable.grinTxMethodHttp()
        if fullInfo.txLogEntry?.confirmed == false && fullInfo.txLogEntry?.txType != .txSentCancelled {
            pageInfo.desc = R.string.localizable.grinDetailTxFinaziledAndPosting()
        }
        return pageInfo
    }

    //MARK: - Done

    func creatSendGrinByFileDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        pageInfo.methodString = R.string.localizable.grinDetailTxFile()
        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        guard let localInfo = fullInfo.localInfo else { return pageInfo }
        guard let txInfo = fullInfo.txLogEntry  else { return pageInfo }

        var openedSalteUrl = fullInfo.openedSalteUrl
        var sendFileUrl = GrinManager.default.getSlateUrl(slateId: localInfo.slateId!, isResponse: false)
        var responseFileUrl = GrinManager.default.getSlateUrl(slateId: localInfo.slateId!, isResponse: true)

        //Details
        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = localInfo.slateId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusImage = R.image.grin_detail_created()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeSent(), attributes: nil)
        cellInfo1.timeStr = txInfo.timeString
        pageInfo.desc = R.string.localizable.grinDetailTxFileCreatedAndCanShare()
        pageInfo.cellInfo.append(cellInfo1)

        let cancleTime = fullInfo.localInfo?.cancleSendTime ?? 0
        let shareSendFileTime = fullInfo.localInfo?.shareSendFileTime ?? 0
        let getResponseFileTime = localInfo.getResponseFileTime ?? 0
        let finalizeTime = localInfo.finalizeTime ?? 0


        let cancelAction = {
            self.infoVM.action.onNext(.cancel(txInfo))
            //self.updatePageInfo()
        }

        let cancleInfo = GrinDetailCellInfo()
        cancleInfo.statusImage = R.image.grin_detail_cancled_gray()
        cancleInfo.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
        cancleInfo.timeStr = cancleTime.grinTimeString()

        if txInfo.txType == .txSentCancelled && ((getResponseFileTime > 0 && cancleTime < getResponseFileTime) || (getResponseFileTime == 0 && cancleTime > getResponseFileTime)) {
            cellInfo1.lineImage = grayLineImage
            pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
            pageInfo.cellInfo.append(cancleInfo)
            return pageInfo
        }

        let cellInfo2 = GrinDetailCellInfo()
        cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeWaitToFinalize(), attributes: nil)
        if let getResponseFileTime = localInfo.getResponseFileTime, getResponseFileTime > 0 {
            pageInfo.desc = R.string.localizable.grinDetailPleaseFinalize()
            cellInfo1.lineImage = blueLineImage
            cellInfo2.statusImage = R.image.grin_detail_waitToSign()
            cellInfo2.timeStr = (getResponseFileTime.grinTimeString())
            pageInfo.actions.append((R.string.localizable.cancel(), cancelAction))
            let finalezeAction = {
                self.txVM.action.onNext(.finalizeTx(slateUrl: openedSalteUrl ?? responseFileUrl))
                //self.updatePageInfo()
            }
            pageInfo.actions.append((R.string.localizable.grinFinalize(), finalezeAction))

            if txInfo.txType == .txSentCancelled && cancleTime >= getResponseFileTime {
                pageInfo.cellInfo.append(cellInfo2)
                cellInfo2.lineImage = grayLineImage
                pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
                pageInfo.cellInfo.append(cancleInfo)
                pageInfo.actions.removeAll()
                return pageInfo
            }
        } else {
            cellInfo1.lineImage = grayLineImage
            cellInfo2.statusImage = R.image.grin_detail_waitToSign_gray()
            pageInfo.actions.append((R.string.localizable.cancel(), cancelAction))
            let shareAction = {
                self.shareSlate(url: openedSalteUrl ?? sendFileUrl)
            }
            pageInfo.actions.append((R.string.localizable.grinShareFile(), shareAction))
        }
        pageInfo.cellInfo.append(cellInfo2)

        if txInfo.confirmed != true && txInfo.txType == .txSentCancelled && cancleTime > 0 && cancleTime > getResponseFileTime && (finalizeTime == 0 || (finalizeTime > 0 && cancleTime < finalizeTime)) {
            cellInfo2.lineImage = grayLineImage
            pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
            pageInfo.cellInfo.append(cancleInfo)
            pageInfo.actions.removeAll()
            return pageInfo
        }

        let cellInfo3 = GrinDetailCellInfo()
        cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeFinalized(), attributes: nil)
        if let finalizeTime = localInfo.finalizeTime, finalizeTime > 0 {
            pageInfo.desc = R.string.localizable.grinDetailTxpostingAndCanRepost()
            cellInfo2.lineImage = blueLineImage
            cellInfo3.statusImage = R.image.grin_detail_poasting()
            cellInfo3.timeStr = localInfo.finalizeTime?.grinTimeString()
            pageInfo.actions.removeAll()
            let repostAction = {
                self.infoVM.action.onNext(.repost(txInfo))
            }
            pageInfo.actions.append((R.string.localizable.grinDetailRepoat(), repostAction))
        } else {
            cellInfo2.lineImage = grayLineImage
            cellInfo3.statusImage = R.image.grin_detail_poasting_gray()
        }
        pageInfo.cellInfo.append(cellInfo3)

        let cellInfo4 = GrinDetailCellInfo()
        if fullInfo.txLogEntry?.confirmed == true {
            pageInfo.desc = R.string.localizable.grinDetailTxCompleted()
            cellInfo4.statusImage = R.image.grin_detail_confirmed()
            cellInfo3.lineImage = blueLineImage
            cellInfo4.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            pageInfo.actions.removeAll()
        } else if txInfo.txType == .txSentCancelled && cancleTime > 0 && cancleTime > getResponseFileTime && cancleTime > finalizeTime {
            pageInfo.desc =  R.string.localizable.grinDetailTxCancelled()
            let cancleInfo = GrinDetailCellInfo()
            cancleInfo.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
            cancleInfo.statusImage = R.image.grin_detail_cancled_gray()
            cellInfo3.lineImage = grayLineImage
            cancleInfo.timeStr = (cancleTime.grinTimeString())
            pageInfo.cellInfo.append(cancleInfo)
            pageInfo.actions.removeAll()
        }  else {
            cellInfo4.statusImage = R.image.grin_detail_confirmed_gray()
            cellInfo3.lineImage = grayLineImage
            cellInfo4.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
        }
        pageInfo.cellInfo.append(cellInfo4)
        return pageInfo
    }

    //MARK: - Done
    func creatSendGrinDetailPageInfoWithoutLocalInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        pageInfo.methodString = R.string.localizable.grinSentTitle()
        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = fullInfo.txLogEntry?.txSlateId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusImage = R.image.grin_detail_created()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeSent(), attributes: nil)
        cellInfo1.timeStr = fullInfo.txLogEntry?.timeString
        pageInfo.cellInfo.append(cellInfo1)

        let cellInfo2 = GrinDetailCellInfo()

        if fullInfo.txLogEntry?.confirmed == true {
            cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            cellInfo2.statusImage = R.image.grin_detail_confirmed()
            cellInfo1.lineImage = blueLineImage
        } else if fullInfo.isSentCancelled {
            cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
            cellInfo2.statusImage = R.image.grin_detail_cancled_gray()
            cellInfo1.lineImage = grayLineImage
        } else {
            cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            cellInfo2.statusImage = R.image.grin_detail_confirmed_gray()
            cellInfo1.lineImage = grayLineImage
            if let txLogEntry = fullInfo.txLogEntry {
                let cancelAction = {
                    self.infoVM.action.onNext(.cancel(txLogEntry))
                    //self.updatePageInfo()
                }
                pageInfo.actions.append((R.string.localizable.cancel(), cancelAction))
            }
        }
        pageInfo.cellInfo.append(cellInfo2)
        return pageInfo
    }

    //MARK: - Done
    func creatReceiveGrinByViteDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        let pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        guard let localInfo = fullInfo.localInfo, localInfo.type == "Receive", localInfo.method == "Vite" else { return pageInfo }

        pageInfo.methodString = R.string.localizable.grinTxMethodVite()
        pageInfo.desc = R.string.localizable.grinTxTypeWaitToSign()

        let cancleTime = fullInfo.localInfo?.cancleSendTime ?? 0
        let getSendFileTime = localInfo.getSendFileTime ?? 0
        let receiveTime = localInfo.receiveTime ?? 0


        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = localInfo.slateId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusImage = R.image.grin_detail_waitToSign()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeWaitToSign(), attributes: nil)
        cellInfo1.timeStr = (localInfo.getSendFileTime?.grinTimeString() )
        pageInfo.cellInfo.append(cellInfo1)

        let cellInfo2 = GrinDetailCellInfo()
        cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeReceived(), attributes: nil)
        cellInfo2.timeStr = (localInfo.receiveTime?.grinTimeString() )

        pageInfo.cellInfo.append(cellInfo2)

        if let txLogEntry = fullInfo.txLogEntry,
            txLogEntry.txType != .txReceivedCancelled,
            txLogEntry.confirmed != true {
            cellInfo2.statusImage = R.image.grin_detail_received()
            cellInfo1.lineImage = blueLineImage
        }

        if fullInfo.txLogEntry == nil || receiveTime == 0 {
            cellInfo2.statusImage = R.image.grin_detail_received_gray()
            cellInfo1.lineImage = grayLineImage
        } else {
            cellInfo2.statusImage = R.image.grin_detail_received()
            cellInfo1.lineImage = blueLineImage
        }

        let cellInfo3 = GrinDetailCellInfo()

        if fullInfo.txLogEntry?.confirmed == true {
            pageInfo.desc = R.string.localizable.grinDetailTxCompleted()
            cellInfo3.statusImage = R.image.grin_detail_confirmed()
            cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            cellInfo2.lineImage = blueLineImage
            cellInfo2.statusImage = R.image.grin_detail_received()
            cellInfo1.lineImage = blueLineImage
            cellInfo1.statusImage = R.image.grin_detail_waitToSign()
        } else if fullInfo.txLogEntry?.txType != .txReceivedCancelled {
            pageInfo.desc = R.string.localizable.grinDetailTxReceived()
            cellInfo3.statusImage = R.image.grin_detail_confirmed_gray()
            cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            cellInfo2.lineImage = grayLineImage
        } else {
            cellInfo3.statusImage = R.image.grin_detail_cancled_gray()
            cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
            cellInfo3.timeStr = localInfo.cancleReceiveTime?.grinTimeString()
            cellInfo2.lineImage = grayLineImage
            pageInfo.desc = R.string.localizable.grinTxTypeCanceled()
            pageInfo.actions.removeAll()
        }
        pageInfo.cellInfo.append(cellInfo3)
        return pageInfo
    }

    //MARK: -
    func creatReceiveGrinByHttpDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        pageInfo.methodString = R.string.localizable.grinTxMethodHttp()

        guard let gatewayInfo = fullInfo.gatewayInfo else {  return pageInfo }

        pageInfo.desc = R.string.localizable.grinDetailGatewayReceived()
        pageInfo.amount = gatewayInfo.fromAmount ?? gatewayInfo.toAmount ?? ""

        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_gateway()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailGateway(), attributes: nil)
        cellInfo0.slateId = gatewayInfo.slatedId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeReceived(), attributes: nil)
        cellInfo1.statusImage = R.image.grin_detail_gateway_received()
        cellInfo1.timeStr = (gatewayInfo.createTime.grinTimeString())
        if let timestamp = gatewayInfo.stepDetailList[0] {
            cellInfo1.timeStr = (timestamp/1000).grinTimeString()
        }

        pageInfo.cellInfo.append(cellInfo1)

        let cellInfo2 = GrinDetailCellInfo()
        if let timestamp = gatewayInfo.stepDetailList[1] {
            cellInfo2.timeStr = (timestamp/1000).grinTimeString()
        }
        cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)

        let curHeight = gatewayInfo.confirmInfo?.curHeight ?? 0
        let beginHeight = gatewayInfo.confirmInfo?.beginHeight ?? 0
        let confirmCount = curHeight - beginHeight
        let gatewayConfirmed = gatewayInfo.confirmInfo?.confirm == true && confirmCount == 0

        if gatewayInfo.confirmInfo?.confirm == true {
            if confirmCount == 0 {
                cellInfo2.statusImage = R.image.grin_detail_gateway_confirmed()
                cellInfo1.lineImage = blueLineImage
                pageInfo.desc = R.string.localizable.grinDetailGatewayConfirmConntBiggerThanTen()
                let action = {
                    //gateway resend
                }
                pageInfo.actions.append(("resend",action))
            } else {
                pageInfo.desc = R.string.localizable.grinDetailGatewayConfirmConntLessThanTen()
                cellInfo2.statusAttributeStr = NSAttributedString.init(string: "\(R.string.localizable.grinTxTypeConfirmed())\(confirmCount)", attributes: nil)

                cellInfo2.statusImage = R.image.grin_detail_gateway_confirmed_gray()
                cellInfo1.lineImage = grayLineImage
            }
        } else {
            cellInfo2.statusImage = R.image.grin_detail_gateway_confirmed_gray()
            cellInfo1.lineImage = grayLineImage
        }
        pageInfo.cellInfo.append(cellInfo2)


        if !gatewayInfo.toSlatedId.isEmpty {
            cellInfo2.lineImage = blueLineImage
        } else {
            cellInfo2.lineImage = grayLineImage
        }

        if fullInfo.localInfo == nil {
            let localInfo = GrinLocalInfo.init()
            localInfo.method = "Vite"
            localInfo.type = "Receive"
            localInfo.slateId = gatewayInfo.toSlatedId
            fullInfo.localInfo = localInfo
        } else {
            (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)
        }


        if let localInfo = fullInfo.localInfo, localInfo.type == "Receive", localInfo.method == "Vite" {

            guard let localInfo = fullInfo.localInfo, localInfo.type == "Receive", localInfo.method == "Vite" else { return pageInfo }

            pageInfo.desc = R.string.localizable.grinDetailTxNotReceivedAndCanAskGatewaytoSend()

            let cancleTime = fullInfo.localInfo?.cancleSendTime ?? 0
            let getSendFileTime = localInfo.getSendFileTime ?? 0
            let receiveTime = localInfo.receiveTime ?? 0

            let cellInfo0 = GrinDetailCellInfo()
            cellInfo0.isTitle = true
            cellInfo0.statusImage = R.image.grin_detail_vite()
            cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailGatewaysend(), attributes: nil)
            cellInfo0.slateId = localInfo.slateId
            cellInfo0.lineImage = blueLineImage
            pageInfo.cellInfo.append(cellInfo0)

            let cellInfo1 = GrinDetailCellInfo()
            cellInfo1.statusImage = R.image.grin_detail_waitToSign()
            cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeWaitToSign(), attributes: nil)
            cellInfo1.timeStr = (localInfo.getSendFileTime?.grinTimeString() )
            pageInfo.cellInfo.append(cellInfo1)

            let cellInfo2 = GrinDetailCellInfo()
            cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeReceived(), attributes: nil)
            cellInfo2.timeStr = (localInfo.receiveTime?.grinTimeString() )

            pageInfo.cellInfo.append(cellInfo2)

            if let txLogEntry = fullInfo.txLogEntry,
                txLogEntry.txType != .txReceivedCancelled,
                txLogEntry.confirmed != true {
                pageInfo.desc =  R.string.localizable.grinDetailTxReceivedAndCanAskGatewaytoSend()
                cellInfo2.statusImage = R.image.grin_detail_received()
                cellInfo1.lineImage = blueLineImage
            }

            if fullInfo.txLogEntry == nil || receiveTime == 0 {
                cellInfo2.statusImage = R.image.grin_detail_received_gray()
                cellInfo1.lineImage = grayLineImage
            } else {
                pageInfo.desc = R.string.localizable.grinDetailTxReceivedAndCanAskGatewaytoSend()
                cellInfo2.statusImage = R.image.grin_detail_received()
                cellInfo1.lineImage = blueLineImage
            }

            let cellInfo3 = GrinDetailCellInfo()

            if fullInfo.txLogEntry?.confirmed == true {
                pageInfo.actions.removeAll()
                pageInfo.desc = R.string.localizable.grinDetailTxCompleted()
                cellInfo3.statusImage = R.image.grin_detail_confirmed()
                cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
                cellInfo2.lineImage = blueLineImage
                cellInfo2.statusImage = R.image.grin_detail_received()
                cellInfo1.lineImage = blueLineImage
                cellInfo1.statusImage = R.image.grin_detail_waitToSign()
            } else if fullInfo.txLogEntry?.txType != .txReceivedCancelled {
                pageInfo.desc = R.string.localizable.grinDetailTxReceived()
                cellInfo3.statusImage = R.image.grin_detail_confirmed_gray()
                cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
                cellInfo2.lineImage = grayLineImage
            } else {
                cellInfo3.statusImage = R.image.grin_detail_cancled_gray()
                cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
                cellInfo3.timeStr = localInfo.cancleReceiveTime?.grinTimeString()
                cellInfo2.lineImage = grayLineImage
                pageInfo.desc = R.string.localizable.grinTxTypeCanceled()
                pageInfo.actions.removeAll()
            }
            pageInfo.cellInfo.append(cellInfo3)
        }
        return pageInfo
    }

    //MARK: - Done

    func creatReceiveGrinByFileDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        pageInfo.methodString = R.string.localizable.grinTxMethodFile()
        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        guard let localInfo = fullInfo.localInfo else { return pageInfo }

        pageInfo.desc = R.string.localizable.grinDetailPleaseReciveAndShare()

        let cancleTime = fullInfo.localInfo?.cancleSendTime ?? 0
        let getSendFileTime = localInfo.getSendFileTime ?? 0
        let receiveTime = localInfo.receiveTime ?? 0

        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = localInfo.slateId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusImage = R.image.grin_detail_waitToSign()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeWaitToSign(), attributes: nil)
        cellInfo1.timeStr = (localInfo.getSendFileTime?.grinTimeString() )
        pageInfo.cellInfo.append(cellInfo1)

        if let url = fullInfo.openedSalteUrl
            {
            let receiveAction = {
                self.txVM.action.onNext(.receiveTx(slateUrl: url))
                //self.updatePageInfo()
            }
            pageInfo.actions.append((R.string.localizable.grinSignAndShare(), receiveAction))
        }

        let cellInfo2 = GrinDetailCellInfo()
        cellInfo2.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeReceived(), attributes: nil)
        if let receiveTime = localInfo.receiveTime, receiveTime > 0 {
            cellInfo2.timeStr = receiveTime.grinTimeString()
        }

        pageInfo.cellInfo.append(cellInfo2)

        if let txLogEntry = fullInfo.txLogEntry,
            txLogEntry.txType != .txReceivedCancelled,
            txLogEntry.confirmed != true {
            pageInfo.actions.removeAll()

            let cancelAction = {
                self.infoVM.action.onNext(.cancel(txLogEntry))
                //self.updatePageInfo()
            }

            pageInfo.actions.append((R.string.localizable.cancel(), cancelAction))

            let url = GrinManager.default.getSlateUrl(slateId: txLogEntry.txSlateId ?? "", isResponse: true)
            if FileManager.default.fileExists(atPath: url.path) {
                let shareAction = {
                    self.shareSlate(url: url)
                }
                pageInfo.actions.append((R.string.localizable.grinShareFile(), shareAction))
            }
            cellInfo2.statusImage = R.image.grin_detail_received()
            cellInfo1.lineImage = blueLineImage
        }

        if fullInfo.txLogEntry == nil || receiveTime == 0 {
            cellInfo2.statusImage = R.image.grin_detail_received_gray()
            cellInfo1.lineImage = grayLineImage
        } else {
            cellInfo2.statusImage = R.image.grin_detail_received()
            cellInfo1.lineImage = blueLineImage
            pageInfo.desc = R.string.localizable.grinDetailTxFileReecivedAndCanShare()
        }

        let cellInfo3 = GrinDetailCellInfo()

        if fullInfo.txLogEntry?.confirmed == true {
            pageInfo.desc = R.string.localizable.grinDetailTxCompleted()
            cellInfo3.statusImage = R.image.grin_detail_confirmed()
            cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            cellInfo2.lineImage = blueLineImage
            cellInfo2.statusImage = R.image.grin_detail_received()
            cellInfo1.lineImage = blueLineImage
            cellInfo1.statusImage = R.image.grin_detail_waitToSign()
        } else if fullInfo.txLogEntry?.txType != .txReceivedCancelled {
            cellInfo3.statusImage = R.image.grin_detail_confirmed_gray()
            cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
            cellInfo2.lineImage = grayLineImage
        } else {
            cellInfo3.statusImage = R.image.grin_detail_cancled_gray()
            cellInfo3.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeCanceled(), attributes: nil)
            cellInfo3.timeStr = localInfo.cancleReceiveTime?.grinTimeString()
            cellInfo2.lineImage = grayLineImage
            pageInfo.desc = R.string.localizable.grinTxTypeCanceled()
            pageInfo.actions.removeAll()
        }
        pageInfo.cellInfo.append(cellInfo3)
        return pageInfo
    }

    //MARK: - Done
    func creatReceiveGrinDetailPageInfoWithoutAnyInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinSentTitle()
        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = fullInfo.txLogEntry?.txSlateId
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmed(), attributes: nil)
        pageInfo.cellInfo.append(cellInfo1)

        guard let txLogEntry =  fullInfo.txLogEntry else {
            return pageInfo
        }

        if txLogEntry.confirmed == true {
            cellInfo0.lineImage = blueLineImage
            cellInfo1.statusImage = R.image.grin_detail_confirmed()
            pageInfo.desc = R.string.localizable.grinDetailTxCompleted()
        } else {
            cellInfo0.lineImage = grayLineImage
            cellInfo1.statusImage = R.image.grin_detail_confirmed_gray()
            pageInfo.desc = R.string.localizable.grinTxTypeReceived()
            let cancelAction = {
                self.infoVM.action.onNext(.cancel(txLogEntry))
                //self.updatePageInfo()
            }
            pageInfo.actions.append((R.string.localizable.cancel(), cancelAction))
        }
        return pageInfo
    }

    //MARK: - Done
    func creatConfirmedCoinbaseDetailPageInfo(fullInfo: GrinFullTxInfo) -> GrinDetailPageInfo {
        var pageInfo = GrinDetailPageInfo()
        pageInfo.title = R.string.localizable.grinDetailFromMine()
        pageInfo.desc = R.string.localizable.grinTxTypeConfirmedCoinbase()

        let cellInfo0 = GrinDetailCellInfo()
        cellInfo0.isTitle = true
        cellInfo0.statusImage = R.image.grin_detail_vite()
        cellInfo0.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinDetailTxStatus(), attributes: nil)
        cellInfo0.slateId = fullInfo.txLogEntry?.txSlateId
        cellInfo0.lineImage = blueLineImage
        pageInfo.cellInfo.append(cellInfo0)

        let cellInfo1 = GrinDetailCellInfo()
        cellInfo1.statusImage = R.image.grin_detail_confirmedconbase()
        cellInfo1.statusAttributeStr = NSAttributedString.init(string: R.string.localizable.grinTxTypeConfirmedCoinbase(), attributes: nil)
        pageInfo.cellInfo.append(cellInfo1)

        (pageInfo.amount, pageInfo.fee) = self.getAmountAndFee(fullInfo: fullInfo)

        cellInfo1.timeStr = fullInfo.txLogEntry?.timeString
        return pageInfo
    }

    //MARK: -
    func getAmountAndFee(fullInfo: GrinFullTxInfo) -> (String?, String?) {
        //Amount and Fee
        var amountString: String?
        var feeString: String?
        if let opendSlateUrl = fullInfo.openedSalteUrl {
            guard let data = JSON(FileManager.default.contents(atPath: opendSlateUrl.path)).rawValue as? [String: Any],
                let slate = Slate(JSON:data) else { return (amountString, feeString) }
             amountString = Balance(value: BigInt(slate.amount)).amount(decimals: 9, count: 9)
             feeString =  Balance(value: BigInt(slate.fee)).amount(decimals: 9, count: 9)
        } else if let txInfo = fullInfo.txLogEntry {
             feeString = "\(Balance(value: BigInt(txInfo.fee ?? 0)).amountShort(decimals:9))"
            let amount = (txInfo.amountCredited ?? 0) - (txInfo.amountDebited ?? 0) + (txInfo.fee ?? 0)
             amountString =  Balance(value: BigInt(abs(amount))).amount(decimals: 9, count: 9)
        }
        if fullInfo.isReceive {
            feeString = nil
        }
        return (amountString, feeString)
    }

    var document: UIDocumentInteractionController!

    func shareSlate(url: URL) {
        var finalUrl = url
        if #available(iOS 11.0, *) {

        } else if #available(iOS 10.0, *) {
            if url.path.contains("grinslate.response") {
                let finalPath = url.path.replacingOccurrences(of: ".grinslate.response", with: ".response.grinslate")
                finalUrl = URL.init(fileURLWithPath: finalPath) ?? url
                do {
                    try  FileManager.default.moveItem(at: url, to: finalUrl)
                } catch {
                    print(error)
                }
            }
        } else {

        }
        guard let vc = Route.getTopVC() else { return }
        document = UIDocumentInteractionController(url: finalUrl)
        document.presentOpenInMenu(from: vc.view.bounds, in: vc.view, animated: true)
    }

    func updatePageInfo() {
        GCD.delay(0) {
            let fullInfo = self.fullInfo
            if let oldLogEntry = fullInfo.txLogEntry {
                do {
                    let (_, txLogEntry) = try GrinManager.default.txGet(refreshFromNode: false, txId: oldLogEntry.id).dematerialize()
                    fullInfo.txLogEntry = txLogEntry
                } catch {

                }
            } else {
                do {
                    let (_, txLogEntries) = try GrinManager.default.txsGet(refreshFromNode: false).dematerialize()
                    if let last = txLogEntries.last, last.txSlateId == fullInfo.localInfo?.slateId {
                        fullInfo.txLogEntry = last
                    }
                } catch {

                }
            }
            if let localSlateId = fullInfo.localInfo?.slateId {
                if fullInfo.isSend {
                    let localInfo = GrinLocalInfoService.shared.getSendInfo(slateId: localSlateId)
                    fullInfo.localInfo = localInfo
                } else if fullInfo.isReceive {
                    let localInfo = GrinLocalInfoService.shared.getReceiveInfo(slateId: localSlateId)
                    fullInfo.localInfo = localInfo
                }
            }
            self.fullInfo = fullInfo
        }
    }
    

}

extension Int {
    fileprivate func grinTimeString() -> String? {
       return TimeInterval(self).grinTimeString()
    }
}

extension TimeInterval {
    fileprivate func grinTimeString() -> String? {
        let date = Date.init(timeIntervalSince1970: self)
        let str = GrinDateFormatter.dateFormatter.string(from: date)
        return str
    }
}

