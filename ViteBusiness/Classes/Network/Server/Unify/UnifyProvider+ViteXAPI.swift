//
//  UnifyProvider+ViteXAPI.swift
//  ViteBusiness
//
//  Created by Stone on 2020/3/17.
//

import RxSwift
import RxCocoa
import Alamofire
import Moya
import SwiftyJSON
import ObjectMapper
import enum Alamofire.Result
import ViteWallet
import APIKit
import JSONRPCKit
import PromiseKit
import Alamofire

extension UnifyProvider {
    struct vitex {}
}

extension UnifyProvider.vitex {

    private static var responseToData: UnifyProvider.ResponseToData {
        return { json throws -> String in
            guard let code = json["code"].int else {
                throw UnifyProvider.BackendError.format
            }

            guard code == 0 else {
                throw UnifyProvider.BackendError.response(code, json["msg"].string ?? "")
            }
            guard let string = json["data"].rawString() else {
                throw UnifyProvider.BackendError.format
            }
            return string
        }
    }

    static func getKlines(symbol: String, type: MarketKlineType) -> Promise<[KlineItem]> {
        let p: MoyaProvider<ViteXAPI> = UnifyProvider.provider()
        return p.requestPromise(.getklines(symbol: symbol, type: type), responseToData: responseToData).map { string in
            let json = JSON(parseJSON: string)
            guard let tArray = json["t"].arrayObject as? [Int64],
                let cArray = json["c"].arrayObject as? [Double],
                let oArray = json["p"].arrayObject as? [Double],
                let hArray = json["h"].arrayObject as? [Double],
                let lArray = json["l"].arrayObject as? [Double],
                let vArray = json["v"].arrayObject as? [Double] else {
                    throw UnifyProvider.BackendError.format
            }

            guard tArray.count == cArray.count,
                tArray.count == oArray.count,
                tArray.count == hArray.count,
                tArray.count == lArray.count,
                tArray.count == vArray.count else {
                    throw UnifyProvider.BackendError.format
            }

            let klineItems = (0..<tArray.count).map {
                KlineItem(t: tArray[$0], c: cArray[$0], o: oArray[$0], h: hArray[$0], l: lArray[$0], v: vArray[$0])
            }

            return klineItems
        }
    }
}