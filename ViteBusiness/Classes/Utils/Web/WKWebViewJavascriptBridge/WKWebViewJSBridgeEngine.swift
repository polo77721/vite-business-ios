//
//  WKWebViewJavascriptBridgeEngine.swift
//  Vite
//
//  Created by Water on 2018/10/22.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import Foundation

protocol WKWebViewJSBridgeEngineDelegate: AnyObject {
    func evaluateJavascript(javascript: String)
    func changeWebVCTitle(title: String)
    func changeWebRRBtn(itemTitle: String?,itemImg:UIImage?)
}

@available(iOS 9.0, *)
public class WKWebViewJSBridgeEngine: NSObject {
    public typealias Callback = (_ responseData: Any?) -> Void
    public typealias Handler = (_ parameters: [String: Any]?, _ callback: Callback?) -> Void
    public typealias FuncJurisdiction = (String, [String])
    public typealias Message = [String: Any]
    public static var keys : [String : FuncJurisdiction] = [
    "bridge.version":("bridgeVersion",[]),
    "app.info":("fetchAppInfo",[]),
    "app.language":("fetchLanguage",[]),
    "app.setWebTitle":("setWebTitle",[]),
    "app.share":("goToshare",[]),
    "app.setRRButton":("setRRButton",[]),
    "wallet.currentAddress":("fetchViteAddress",[]),
    "wallet.sendTxByURI":("invokeUri",[])
    ]

    weak var delegate: WKWebViewJSBridgeEngineDelegate?
    var startupMessageQueue = [Message]()
    var responseCallbacks = [String: Callback]()
    var messageHandlers = [String: Handler]()
    var uniqueId = 0

    func reset() {
        startupMessageQueue = [Message]()
        responseCallbacks = [String: Callback]()
        uniqueId = 0
    }

    func send(handlerName: String, data: Any?, callback: Callback?) {
        var message = [String: Any]()
        message["handlerName"] = handlerName

        if data != nil {
            message["data"] = data
        }

        if callback != nil {
            uniqueId += 1
            let callbackID = "native_iOS_cb_\(uniqueId)"
            responseCallbacks[callbackID] = callback
            message["callbackID"] = callbackID
        }

        queue(message: message)
    }

    public func sendResponds(_ message: Message) {
        self.queue(message: message)
    }

    func flush(messageQueueString: String, url: String) {
        guard let messages = deserialize(messageJSON: messageQueueString) else {
            print(messageQueueString)
            return
        }

        for message in messages {
            print(message)

            if let responseID = message["responseID"] as? String {
                guard let callback = responseCallbacks[responseID] else { continue }
                callback(message["responseData"])
                responseCallbacks.removeValue(forKey: responseID)
            } else {
                var  callback: Callback?
                if let callbackID = message["callbackID"] {
                    callback = { (_ responseData: Any?) -> Void in
                        let msg = ["responseID": callbackID, "responseData": responseData ?? NSNull()] as Message
                        self.queue(message: msg)
                    }
                } else {
                    callback = { (_ responseData: Any?) -> Void in
                        // no logic
                    }
                    return
                }

                guard let key = message["handlerName"] as? String else { return }

                guard let handlerFuncJurisdiction = self.mapFunName(key) as? FuncJurisdiction else {
                    self.sendErrorRequest(responseID: message["callbackID"], responseData: ResponseCode.noJurisdictionResult(msg: "no func"))
                    return
                }
                let handlerName = handlerFuncJurisdiction.0
                let jurisdiction = handlerFuncJurisdiction.1
                //check url has this func jurisdiction
                if !self.checkUrlHasJurisdiction(url: url,jurisdictions: jurisdiction) {
                    self.sendErrorRequest(responseID: message["callbackID"], responseData: ResponseCode.noJurisdictionResult(msg: "no jurisdiction"))
                    return
                }

                let aSel: Selector = NSSelectorFromString("jsapi_" + handlerName+("WithParameters:callbackID:"))//
                let isResponds = self.responds(to: aSel)
                if isResponds {
                    //handle input parameters
                    guard let input = message["data"] as? [String:Any]  else {
                        self.perform(aSel, with: nil, with: message["callbackID"])
                        return
                    }
                    self.perform(aSel, with: input, with: message["callbackID"])
                } else {
                    guard let handler = messageHandlers[handlerName] else {
                        self.sendErrorRequest(responseID: message["callbackID"], responseData: ResponseCode.noJurisdictionResult(msg: "no handler"))
                        return
                    }
                    handler(message["data"] as? [String: Any], callback)
                }
            }
        }
    }

    func mapFunName(_ key:String) -> FuncJurisdiction? {
        return WKWebViewJSBridgeEngine.keys[key]
    }

    func injectJavascriptFile() {
        let js = InjectJSBridgeJS
        delegate?.evaluateJavascript(javascript: js)
    }

    // MARK: - Private
    private func queue(message: Message) {
        if startupMessageQueue.isEmpty {
            dispatch(message: message)
        } else {
            startupMessageQueue.append(message)
        }
    }

    // MARK: - Private
    private func dispatch(message: Message) {
        guard var messageJSON = serialize(message: message, pretty: false) else { return }

        messageJSON = messageJSON.replacingOccurrences(of: "\\", with: "\\\\")
        messageJSON = messageJSON.replacingOccurrences(of: "\"", with: "\\\"")
        messageJSON = messageJSON.replacingOccurrences(of: "\'", with: "\\\'")
        messageJSON = messageJSON.replacingOccurrences(of: "\n", with: "\\n")
        messageJSON = messageJSON.replacingOccurrences(of: "\r", with: "\\r")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{000C}", with: "\\f")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2029}", with: "\\u2029")

        let javascriptCommand = "WKWebViewJavascriptBridge._handleMessageFromiOS('\(messageJSON)');"
        if Thread.current.isMainThread {
            delegate?.evaluateJavascript(javascript: javascriptCommand)
        } else {
            DispatchQueue.main.async {
                self.delegate?.evaluateJavascript(javascript: javascriptCommand)
            }
        }
    }

    // MARK: - JSON
    public func serialize(message: Message, pretty: Bool) -> String? {
        var result: String?
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: pretty ? .prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0))
            result = String(data: data, encoding: .utf8)
        } catch let error {
            print(error)
        }
        return result
    }

  public func deserialize(messageJSON: String) -> [Message]? {
        var result = [Message]()
        guard let data = messageJSON.data(using: .utf8) else { return nil }
        do {
            result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [WKWebViewJSBridgeEngine.Message]
        } catch let error {
            print(error)
        }
        return result
    }
}

extension WKWebViewJSBridgeEngine {
    class func parseOutputParameters(_ response:Response?) -> String?{
        response
        return response?.toJSONString(prettyPrint: true)
    }
}

extension WKWebViewJSBridgeEngine {
    func sendErrorRequest(responseID:Any?,responseData:String?) {
        let message = ["responseID": responseID, "responseData": responseData]
        self.sendResponds(message)
    }
}

extension WKWebViewJSBridgeEngine {
    func checkUrlHasJurisdiction(url:String,jurisdictions:[String])->Bool {
        #if DEBUG 
        return true
        #else
        if jurisdictions.count == 0 {
            return true
        }else {
            return  jurisdictions.contains(url)
        }
        #endif
    }
}
