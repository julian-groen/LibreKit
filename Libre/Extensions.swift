//
//  Extensions.swift
//  Libre2Client
//
//  Created by Reimar Metzen on 12.03.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
import CryptoKit

extension UInt8 {
    var hex: String { String(format: "%.2X", self) }
}

extension UInt16 {
    /// initializer taking 2 bytes as parameter, first the high byte then the low byte
    init(_ high: UInt8, _ low: UInt8) {
        self = UInt16(high) << 8 + UInt16(low)
    }

    /// init from data[low...high]
    init(_ data: Data) {
        self = UInt16(data[data.startIndex + 1]) << 8 + UInt16(data[data.startIndex])
    }
    
    var hex: String { String(format: "%04x", self) }
}

extension Data {
    var hex: String { self.reduce("", { $0 + String(format: "%02x", $1)}) }
    var string: String { String(decoding: self, as: UTF8.self) }
    var hexAddress: String { String(self.reduce("", { $0 + $1.hex + ":"}).dropLast(1)) }
    var sha1: String { Insecure.SHA1.hash(data: self).makeIterator().reduce("", { $0 + String(format: "%02x", $1)}) }
}
