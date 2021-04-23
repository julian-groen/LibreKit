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
        case let x where x <= 0.9:
            return .critical
        case let x where x <= 0.7:
            return .warning
        default:
            return .normalCGM
        }
    }
}
