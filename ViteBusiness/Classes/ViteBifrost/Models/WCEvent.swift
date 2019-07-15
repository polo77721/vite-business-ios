//
//  WCEvent.swift
//  WalletConnect
//
//  Created by Tao Xu on 4/1/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public enum WCEvent: String {
    case sessionRequest = "vb_sessionRequest"
    case sessionUpdate = "vb_sessionUpdate"
    case exchangeKey = "vb_exchangeKey"

    case sessionPeerPing = "vb_peerPing"
    case viteSendTx = "vite_signAndSendTx"
}

extension WCEvent {
    func decode<T: Codable>(_ data: Data) throws -> JSONRPCRequest<T> {
        return try JSONDecoder().decode(JSONRPCRequest<T>.self, from: data)
    }
}
