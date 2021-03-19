//
//  UserDefaults+Libre2.swift
//  LibreKit
//
//  Created by Reimar Metzen on 11.03.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation

extension UserDefaults {
    private enum Key: String {
        case transmitterID = "com.librekit.sensor.transmitter"
        case sensorUnlockCount = "com.librekit.sensor.sensorUnlockCount"
        case sensorUID = "com.librekit.sensor.sensorUID"
        case sensorPatchInfo = "com.librekit.sensor.sensorPatchInfo"
        case sensorCalibrationInfo = "com.librekit.sensor.sensorCalibrationInfo"
        case sensorState = "com.librekit.sensor.sensorState"
        case sensorSerial = "com.librekit.sensor.sensorSerial"
        case lastSensorAge = "com.librekit.sensor.lastSensorAge"
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

    var sensorUnlockCount: UInt16? {
        get {
            return UInt16(integer(forKey: Key.sensorUnlockCount.rawValue))
        }
        set {
            set(newValue, forKey: Key.sensorUnlockCount.rawValue)
        }
    }
    
    var sensorUID: Data? {
        get {
            return object(forKey: Key.sensorUID.rawValue) as? Data
        }
        set {
            set(newValue, forKey: Key.sensorUID.rawValue)
        }
    }
    
    var sensorPatchInfo: Data? {
        get {
            return object(forKey: Key.sensorPatchInfo.rawValue) as? Data
        }
        set {
            set(newValue, forKey: Key.sensorPatchInfo.rawValue)
        }
    }
    
    var sensorType: SensorType? {
        get {
            if let patchInfo = UserDefaults.standard.sensorPatchInfo {
                return SensorType(patchInfo: patchInfo)
            }
            
            return nil
        }
    }
    
    var sensorRegion: SensorRegion? {
        get {
            if let patchInfo = UserDefaults.standard.sensorPatchInfo {
                return SensorRegion(patchInfo: patchInfo)
            }
            
            return nil
        }
    }
    
    var sensorState: SensorState? {
        get {
            if let saved = object(forKey: Key.sensorState.rawValue) as? Data {
                let decoder = JSONDecoder()
                
                if let loaded = try? decoder.decode(SensorState.self, from: saved) {
                    return loaded
                }
            }
            
            return nil
        }
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                set(encoded, forKey: Key.sensorState.rawValue)
            }
        }
    }
    
    var sensorSerial: String? {
        get {
            return string(forKey: Key.sensorSerial.rawValue)
        }
        set {
            set(newValue, forKey: Key.sensorSerial.rawValue)
        }
    }
    
    var sensorCalibrationInfo: CalibrationInfo? {
        get {
            if let saved = object(forKey: Key.sensorCalibrationInfo.rawValue) as? Data {
                let decoder = JSONDecoder()
                
                if let loaded = try? decoder.decode(CalibrationInfo.self, from: saved) {
                    return loaded
                }
            }
            
            return nil
        }
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                set(encoded, forKey: Key.sensorCalibrationInfo.rawValue)
            }
        }
    }
    
    var lastSensorAge: Int? {
        get {
            return integer(forKey: Key.lastSensorAge.rawValue)
        }
        set {
            set(newValue, forKey: Key.lastSensorAge.rawValue)
        }
    }
}
