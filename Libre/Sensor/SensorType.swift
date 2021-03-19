//
//  SensorType.swift
//  LibreKit
//
//  Created by Reimar Metzen on 01.03.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation

fileprivate extension String {
    //https://stackoverflow.com/questions/39677330/how-does-string-substring-work-in-swift
    //usage
    //let s = "hello"
    //s[0..<3] // "hel"
    //s[3..<s.count] // "lo"
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}

public enum SensorType: String {
    case libre1 = "Libre 1"
    case libre2 = "Libre 2"
    case libreUS14day = "Libre US 14d"
    case libre2US = "Libre 2 US"
    case libreProH = "Libre Pro/H"
    case libreSense = "Libre Sense"
    case libre3 = "Libre 3"
    case unknown = "Libre"

    init() {
        self = .unknown
    }

    init(patchInfo: Data) {
        switch patchInfo[0] {
        case 0xDF:
            self = .libre1
        case 0xA2:
            self = .libre1
        case 0x9D:
            self = .libre2
        case 0xE5:
            self = .libreUS14day
        case 0x76:
            self = .libre2US
        case 0x70:
            self = .libreProH
        default:
            self = .unknown
        }
    }

    static func type(patchInfo: String?) -> SensorType? {
        guard let patchInfo = patchInfo else {
            return .libre1
        }

        guard patchInfo.count > 1 else {
            return nil
        }

        let firstTwoChars = patchInfo[0..<2].uppercased()

        switch firstTwoChars {
        case "DF":
            return .libre1
        case "A2":
            return .libre1
        case "9D":
            return .libre2
        case "E5":
            return .libreUS14day
        case "70":
            return .libreProH
        default:
            return nil
        }
    }
}
