//
//  HDWalletStorage.swift
//  Vite
//
//  Created by Stone on 2018/10/8.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit
import Vite_HDWalletKit
import ObjectMapper
import CryptoSwift
import ViteUtils

final class HDWalletStorage: Mappable {

    fileprivate var fileHelper = FileHelper(.library, appending: FileHelper.appPathComponent)
    fileprivate static let saveKey = "HDWallet"
    fileprivate(set) var wallets = [Wallet]()
    fileprivate var currentWalletUuid: String?
    fileprivate var isLogin: Bool = false

    init() {
        if let data = fileHelper.contentsAtRelativePath(type(of: self).saveKey),
            let jsonString = String(data: data, encoding: .utf8),
            let storage = HDWalletStorage(JSONString: jsonString) {
            self.wallets = storage.wallets
            self.currentWalletUuid = storage.currentWalletUuid
            self.isLogin = storage.isLogin
        }
    }

    init?(map: Map) {}

    func mapping(map: Map) {
        wallets <- map["wallets"]
        currentWalletUuid <- map["currentWalletUuid"]
        isLogin <- map["isLogin"]
    }

    var currentWallet: Wallet? {
        guard isLogin else { return nil }
        if let uuid = currentWalletUuid,
            let (_, wallet) = pri_walletAndIndexForUuid(uuid) {
            return wallet
        } else {
            return nil
        }
    }

    var currentWalletIndex: Int? {
        guard let uuid = currentWalletUuid else { return nil }
        for (index, wallet) in wallets.enumerated() where wallet.uuid == uuid {
            return index
        }

        return nil
    }
}

// MARK: - public function
extension HDWalletStorage {

    func addAddLoginWallet(uuid: String, name: String, mnemonic: String, hash: String, encryptKey: String, needRecoverAddresses: Bool) -> Wallet {
        let wallet = Wallet(uuid: uuid, name: name, mnemonic: mnemonic, hash: hash, encryptKey: encryptKey, needRecoverAddresses: needRecoverAddresses)

        var index: Int?
        for (i, wallet) in wallets.enumerated() where wallet.hash == hash {
            index = i
        }

        if let index = index {
            wallets.remove(at: index)
            wallets.insert(wallet, at: index)
        } else {
            wallets.append(wallet)
        }

        currentWalletUuid = uuid
        isLogin = true
        pri_save()
        return wallet
    }

    func login(encryptKey: String, uuid: String? = nil) -> (Wallet, String)? {
        let uuid = uuid ?? self.currentWalletUuid ?? ""
        guard let (_, wallet) = pri_walletAndIndexForUuid(uuid) else { return nil }
        currentWalletUuid = wallet.uuid
        isLogin = true
        pri_save()

        if let mnemonic = wallet.mnemonic(encryptKey: encryptKey) {
            return (wallet, mnemonic)
        } else {
            return nil
        }
    }

    func logout() {
        isLogin = false
        pri_save()
    }

    func deleteAllWallets() {
        currentWalletUuid = nil
        isLogin = false
        wallets = [Wallet]()
        pri_save()
    }

    func updateCurrentWalletName(_ name: String) -> Wallet? {
        return pri_updateWalletForUuid(nil) { (wallet) in
            wallet.name = name
        }
    }

    func updateCurrentWallet(addressIndex: Int, addressCount: Int, needRecoverAddresses: Bool? = nil) -> Wallet? {
        return pri_updateWalletForUuid(nil) { (wallet) in
            wallet.addressIndex = addressIndex
            wallet.addressCount = addressCount
            if let needRecoverAddresses = needRecoverAddresses {
                wallet.needRecoverAddresses = needRecoverAddresses
            }
        }
    }

    func updateCurrentWallet(isRequireAuthentication: Bool? = nil, isAuthenticatedByBiometry: Bool? = nil, isTransferByBiometry: Bool? = nil) -> Wallet? {
        return pri_updateWalletForUuid(nil) { (wallet) in
            if let ret = isRequireAuthentication {
                wallet.isRequireAuthentication = ret
            }
            if let ret = isAuthenticatedByBiometry {
                wallet.isAuthenticatedByBiometry = ret
            }
            if let ret = isTransferByBiometry {
                wallet.isTransferByBiometry = ret
            }
        }
    }
}

// MARK: - private function
extension HDWalletStorage {

    fileprivate func pri_updateWalletForUuid(_ uuid: String? = nil, block: (inout Wallet) -> Void) -> Wallet? {
        let uuid = uuid ?? self.currentWalletUuid ?? ""
        guard let (index, w) = pri_walletAndIndexForUuid(uuid) else { return nil }
        var wallet = w
        block(&wallet)
        wallets.remove(at: index)
        wallets.insert(wallet, at: index)
        pri_save()
        return wallet
    }

    fileprivate func pri_walletAndIndexForUuid(_ uuid: String) -> (Int, Wallet)? {
        for (index, wallet) in wallets.enumerated() where wallet.uuid == uuid {
            return (index, wallet)
        }
        return nil
    }

    fileprivate func pri_save() {
        if let data = self.toJSONString()?.data(using: .utf8) {
            if let error = fileHelper.writeData(data, relativePath: type(of: self).saveKey) {
                assert(false, error.localizedDescription)
            }
        }
    }
}

extension HDWalletStorage {

    struct Wallet: Mappable {

        fileprivate(set) var uuid: String = ""
        fileprivate(set) var name: String = ""
        fileprivate(set) var ciphertext: String?
        fileprivate(set) var hash: String?

        fileprivate(set) var addressIndex: Int = 0
        fileprivate(set) var addressCount: Int = 1
        fileprivate(set) var needRecoverAddresses: Bool = true

        fileprivate(set) var isRequireAuthentication: Bool = false
        fileprivate(set) var isAuthenticatedByBiometry: Bool = false
        fileprivate(set) var isTransferByBiometry: Bool = false

        init?(map: Map) {}

        init(uuid: String = "",
             name: String = "",
             mnemonic: String = "",
             hash: String = "",
             encryptKey: String = "",
             addressIndex: Int = 0,
             addressCount: Int = 1,
             needRecoverAddresses: Bool = true,
             isRequireAuthentication: Bool = false,
             isAuthenticatedByBiometry: Bool = false,
             isTransferByBiometry: Bool = false) {

            self.uuid = uuid
            self.name = name
            self.ciphertext = type(of: self).encrypt(plaintext: mnemonic, encryptKey: encryptKey)
            self.hash = hash

            self.addressIndex = addressIndex
            self.addressCount = addressCount
            self.needRecoverAddresses = needRecoverAddresses

            self.isRequireAuthentication = isRequireAuthentication
            self.isAuthenticatedByBiometry = isAuthenticatedByBiometry
            self.isTransferByBiometry = isTransferByBiometry
        }

        func mnemonic(encryptKey: String) -> String? {
            guard let ciphertext = ciphertext else { return nil }
            return type(of: self).decrypt(ciphertext: ciphertext, encryptKey: encryptKey)
        }

        mutating func mapping(map: Map) {
            uuid <- map["uuid"]
            name <- map["name"]
            ciphertext <- map["ciphertext"]
            hash <- map["hash"]

            addressIndex <- map["addressIndex"]
            addressCount <- map["addressCount"]
            needRecoverAddresses <- map["needRecoverAddresses"]

            isRequireAuthentication <- map["isRequireAuthentication"]
            isAuthenticatedByBiometry <- map["isAuthenticatedByBiometry"]
            isTransferByBiometry <- map["isTransferByBiometry"]
        }

        static let gcm = GCM(iv: "vite mnemonic iv".md5().hex2Bytes, mode: .combined)

        static func encrypt(plaintext: String, encryptKey: String) -> String? {
            do {
                guard let data = encryptKey.data(using: .utf8) else { return nil }
                guard let entropy = Mnemonic.mnemonicsToEntropy(plaintext) else { return nil }
                let key = [UInt8](data.sha256())
                let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
                let cipher = try aes.encrypt([UInt8](entropy))
                return cipher.toHexString()
            } catch {
                return nil
            }
        }

        static func decrypt(ciphertext: String, encryptKey: String) -> String? {
            do {
                guard let data = encryptKey.data(using: .utf8) else { return nil }
                let key = [UInt8](data.sha256())
                let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
                let entropy = try aes.decrypt(ciphertext.hex2Bytes)
                return Mnemonic.generator(entropy: Data(bytes: entropy))
            } catch {
                return nil
            }
        }
    }
}
