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
    
    public var glucose: Double
    
    public var trend: GlucoseTrend
    
    public var timestamp: TimeInterval
    
    public var minutes: Int
}
    
extension SensorReading: GlucoseValue {
    
    public var startDate: Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: glucose)
    }
}

extension SensorReading: GlucoseDisplayable {
    
    public var isStateValid: Bool {
        return glucose >= 39
    }
    
    public var trendType: GlucoseTrend? {
        return .flat
    }
    
    public var isLocal: Bool {
        return true
    }
    
    public var glucoseRangeCategory: GlucoseRangeCategory? {
        return nil
    }
}

extension SensorReading: DeviceStatusHighlight {
    
    public var localizedMessage: String {
        return "Battery Low"
    }
    
    public var imageName: String {
        return "exclamationmark.circle.fill"
    }
    
    public var state: DeviceStatusHighlightState {
        return .normalCGM
    }
}

extension SensorReading: DeviceLifecycleProgress {
    
    public var percentComplete: Double {
        return 0.5
    }
    
    public var progressState: DeviceLifecycleProgressState {
        return .normalCGM
    }
}
