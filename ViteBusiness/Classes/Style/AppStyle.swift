//
//  AppStyle.swift
//  Vite
//
//  Created by Water on 2018/9/5.
//  Copyright © 2018年 vite labs. All rights reserved.
//

import UIKit

// screen height
let kScreenH = UIScreen.main.bounds.height
// screen width
let kScreenW = UIScreen.main.bounds.width
//Adaptive iPhoneX
let kNavibarH: CGFloat = UIDevice.current.isIPhoneX() ? 88.0 : 64.0

extension UIDevice {
    public func isIPhoneX() -> Bool {
        if kScreenH == 812 {
            return true
        }
        return false
    }
    public func isIPhone6() -> Bool {
        if kScreenH == 667 {
            return true
        }
        return false
    }
    public func isIPhone6Plus() -> Bool {
        if kScreenH == 736 {
            return true
        }
        return false
    }
}
struct Fonts {
    static let descFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    static let light14 = UIFont.systemFont(ofSize: 14, weight: .light)
    static let light16 = UIFont.systemFont(ofSize: 16, weight: .light)
    static let Font12 = UIFont.systemFont(ofSize: 12, weight: .semibold)
    static let Font14 = UIFont.systemFont(ofSize: 14, weight: .regular)
    static let Font14_b = UIFont.systemFont(ofSize: 14, weight: .semibold)
    static let Font16_b = UIFont.systemFont(ofSize: 16, weight: .semibold)
    static let Font17 = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let Font18 = UIFont.systemFont(ofSize: 18, weight: .regular)
    static let Font20 = UIFont.systemFont(ofSize: 20, weight: .semibold)
    static let Font24 = UIFont.systemFont(ofSize: 24, weight: .semibold)
}

enum AppStyle {
    case inputDescWord
    case descWord
    case heading
    case headingSemiBold
    case paragraph
    case paragraphLight
    case paragraphSmall
    case largeAmount
    case error
    case formHeader
    case collactablesHeader

    var font: UIFont {
        switch self {
        case .inputDescWord:
            return UIFont.systemFont(ofSize: 18, weight: .regular)
        case .descWord:
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        case .heading:
            return UIFont.systemFont(ofSize: 18, weight: .regular)
        case .headingSemiBold:
            return UIFont.systemFont(ofSize: 18, weight: .semibold)
        case .paragraph:
            return UIFont.systemFont(ofSize: 15, weight: .regular)
        case .paragraphSmall:
            return UIFont.systemFont(ofSize: 14, weight: .regular)
        case .paragraphLight:
            return UIFont.systemFont(ofSize: 15, weight: .light)
        case .largeAmount:
            return UIFont.systemFont(ofSize: 20, weight: .medium)
        case .error:
            return UIFont.systemFont(ofSize: 13, weight: .light)
        case .formHeader:
            return UIFont.systemFont(ofSize: 14, weight: .regular)
        case .collactablesHeader:
            return UIFont.systemFont(ofSize: 21, weight: UIFont.Weight.regular)
        }
    }

    var textColor: UIColor {
        switch self {
        case .heading, .headingSemiBold:
            return Colors.darkBlue
        case .paragraph, .paragraphLight, .paragraphSmall:
            return Colors.darkBlue
        case .largeAmount:
            return UIColor.black
        case .error:
            return Colors.darkBlue
        case .formHeader:
            return Colors.darkBlue
        case .collactablesHeader, .inputDescWord:
            return Colors.darkBlue
        case .descWord:
            return Colors.titleGray
        }
    }
}

extension CGFloat {
    static var singleLineWidth: CGFloat { return 1.0 / UIScreen.main.scale }
}
