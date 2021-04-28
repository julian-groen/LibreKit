//
//  SensorReading.swift
//  LibreKit
//
//  Created by Julian Groen on 21/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit
import HealthKit


public struct SensorReading {
    
    public var glucoseValue: Double
    
    public var glucoseTrend: GlucoseTrend
    
    public var sensorState: SensorState
    
    public var timestamp: TimeInterval
    
    public var minutesSinceStart: Int
    
    public var minutesTillExpire: Int
    
    public init(_ packet: SensorPacket, value: Double, timestamp: TimeInterval) {
        self.glucoseValue = value
        self.glucoseTrend = .flat
        self.sensorState = packet.sensorState
        self.minutesSinceStart = packet.minutesSinceStart
        self.minutesTillExpire = packet.minutesTillExpire
        self.timestamp = timestamp
    }
}
    
extension SensorReading: GlucoseValue {
    
    public var startDate: Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    public var quantity: HKQuantity {
        return HKQuantity(
            unit: .milligramsPerDeciliter, doubleValue: glucoseValue
        )
    }
}

extension SensorReading: GlucoseDisplayable {
    
    public var isStateValid: Bool {
        return glucoseValue >= 39
    }
    
    public var trendType: GlucoseTrend? {
        return glucoseTrend
    }
    
    public var isLocal: Bool {
        return true
    }
    
    public var glucoseRangeCategory: GlucoseRangeCategory? {
        return .normal
    }
}

extension SensorReading: DeviceStatusHighlight {
    
    public var localizedMessage: String {
        return "Sensor Expired"
    }
    
    public var imageName: String {
        return "exclamationmark.circle.fill"
    }
    
    public var state: DeviceStatusHighlightState {
        return .critical
    }
}

extension SensorReading: DeviceLifecycleProgress {
    
    public var percentComplete: Double {
        return 1.0 - Double(minutesSinceStart) / Double(minutesTillExpire)
    }
    
    public var progressState: DeviceLifecycleProgressState {
        switch (percentComplete) {
        case let x where x <= 0.1:
            return .critical
        case let x where x <= 0.3:
            return .warning
        default:
            return .normalCGM
        }
    }
}
