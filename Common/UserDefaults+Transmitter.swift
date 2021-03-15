//
//  UserDefaults+Transmitter.swift
//  LibreKit
//
//  Created by Julian Groen on 29/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

extension UserDefaults {
    private enum Key: String {
        case transmitterIdentifier = "com.librekit.transmitter.identifier"
    }

    public var transmitterIdentifier: UUID? {
        get {
            if let uuid = string(forKey: Key.transmitterIdentifier.rawValue) {
                return UUID(uuidString: uuid)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                set(newValue.uuidString, forKey: Key.transmitterIdentifier.rawValue)
            } else {
                removeObject(forKey: Key.transmitterIdentifier.rawValue)
            }
        }
    }
}
