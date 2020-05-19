//
//  UserDefaults+Bluetooth.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

extension UserDefaults {
    private enum Key: String {
        case transmitterID = "com.librekit.bluetooth.transmitter"
    }

    public var transmitterID: String? {
        get {
            if let astr = string(forKey: Key.transmitterID.rawValue) {
                return astr.count > 0 ? astr : nil
            }
            return nil
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Key.transmitterID.rawValue)
            } else {
                removeObject(forKey: Key.transmitterID.rawValue)
            }
        }
    }
}
