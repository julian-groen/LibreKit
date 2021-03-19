//
//  UserDefaults+Glucose.swift
//  LibreKit
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import HealthKit

extension UserDefaults {
    private enum Key: String {
        case glucoseUnit    = "com.librekit.glucose.unit"
        case glucoseSync    = "com.librekit.glucose.sync"
    }
    
    var glucoseSync: Bool {
        get {
            return optional(forKey: Key.glucoseSync.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.glucoseSync.rawValue)
        }
    }
    
    var glucoseUnit: HKUnit? {
        get {
            if let textUnit = string(forKey: Key.glucoseUnit.rawValue) {
                return (textUnit == "mmol" ? HKUnit.millimolesPerLiter : HKUnit.milligramsPerDeciliter)
            }
            return nil
        }
        set {
            switch newValue {
            case HKUnit.milligramsPerDeciliter:
                set("mgdl", forKey: Key.glucoseUnit.rawValue)
            case HKUnit.millimolesPerLiter:
                set("mmol", forKey: Key.glucoseUnit.rawValue)
            default:
                return
            }
        }
    }
    
}
