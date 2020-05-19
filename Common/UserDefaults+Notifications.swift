//
//  UserDefaults+Notifications.swift
//  LibreKit
//
//  Created by Julian Groen on 16/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

extension UserDefaults {
    private enum Key: String {
        case enabled        = "com.librekit.notifications.enabled"
        case lowBattery     = "com.librekit.notifications.lowBattery"
        case sensorExpire   = "com.librekit.notifications.sensorExpire"
        case noSensor       = "com.librekit.notifications.noSensor"
        case newSensor      = "com.librekit.notifications.newSensor"
    }

    var notificationsEnabled: Bool? {
        get {
            return optional(forKey: Key.enabled.rawValue)
        }
        set {
            set(newValue, forKey: Key.enabled.rawValue)
        }
    }
    
    var lowBatteryNotification: Bool {
        get {
            return optional(forKey: Key.lowBattery.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.lowBattery.rawValue)
        }
    }
    
    var newSensorNotification: Bool {
        get {
            return optional(forKey: Key.newSensor.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.newSensor.rawValue)
        }
    }
    
    var noSensorNotification: Bool {
        get {
            return optional(forKey: Key.noSensor.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.noSensor.rawValue)
        }
    }
    
    var sensorExpireNotification: Bool {
        get {
            return optional(forKey: Key.sensorExpire.rawValue) ?? true
        }
        set {
            set(newValue, forKey: Key.sensorExpire.rawValue)
        }
    }
    
}
