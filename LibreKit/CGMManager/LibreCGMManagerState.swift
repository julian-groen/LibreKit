//
//  LibreCGMManagerState.swift
//  LibreKit
//
//  Created by Julian Groen on 19/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit


public struct LibreCGMManagerState: RawRepresentable, Equatable {
    
    public typealias RawValue = CGMManager.RawStateValue
    
    public var lastSensorPacket: SensorPacket?

    public var transmitterState: TransmitterState?
    
    public var alarmNotifications: Bool
    
    public var glucoseTargetRange: DoubleRange
    
    public init(lastSensorPacket: SensorPacket? = nil, transmitterState: TransmitterState? = nil) {
        self.lastSensorPacket = lastSensorPacket
        self.transmitterState = transmitterState
        self.glucoseTargetRange = DoubleRange(minValue: 70.0, maxValue: 180.0)
        self.alarmNotifications = true
    }
    
    public init?(rawValue: RawValue) {
        var lastSensorPacket: SensorPacket?
        if let rawObjectValue = rawValue["lastSensorPacket"] as? SensorPacket.RawValue {
            lastSensorPacket = SensorPacket(rawValue: rawObjectValue)
        }
        
        var transmitterState: TransmitterState?
        if let rawObjectValue = rawValue["transmitterState"] as? TransmitterState.RawValue {
            transmitterState = TransmitterState(rawValue: rawObjectValue)
        }
        
        self.init(lastSensorPacket: lastSensorPacket, transmitterState: transmitterState)
        self.alarmNotifications = (rawValue["alarmNotifications"] as? Bool) ?? true
    
        if let rawObjectValue = rawValue["glucoseTargetRange"] as? DoubleRange.RawValue {
            self.glucoseTargetRange = DoubleRange(rawValue: rawObjectValue)!
        }
    }
    
    public var rawValue: RawValue {
        var value: [String : Any] = [
            "alarmNotifications": alarmNotifications,
            "glucoseTargetRange": glucoseTargetRange.rawValue
        ]
        
        if let lastSensorPacket = lastSensorPacket {
            value["lastSensorPacket"] = lastSensorPacket.rawValue
        }

        if let transmitterState = transmitterState {
            value["transmitterState"] = transmitterState.rawValue
        }
        
        return value
    }
}
 
extension LibreCGMManagerState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "## LibreCGMManagerState",
            "* alarmNotifications: \(String(describing: alarmNotifications))",
            "* glucoseTargetRange: \(String(describing: glucoseTargetRange))",
            "* transmitterState: \(String(reflecting: transmitterState))",
            "* lastSensorPacket: \(String(reflecting: lastSensorPacket))"
        ].joined(separator: "\n")
    }
}
