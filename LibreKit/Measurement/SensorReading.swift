//
//  SensorReading.swift
//  LibreKit
//
//  Created by Julian Groen on 21/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit
import LoopKitUI
import HealthKit


public struct SensorReading: GlucoseValue, GlucoseDisplayable {
    
    public var isLocal: Bool = true
    
    public var glucoseValue: Double
    
    public var sensorState: SensorState
    
    public var timestamp: TimeInterval
    
    public var minutesSinceStart: Int
    
    public var minutesTillExpire: Int
    
    public var statusHighlight: DeviceStatusHighlight?
    
    public var statusBadge: DeviceStatusBadge?
    
    public var glucoseRangeCategory: GlucoseRangeCategory?
    
    public var trendType: GlucoseTrend?
    
    public init(_ packet: SensorPacket, value: Double, timestamp: TimeInterval) {
        self.glucoseValue = value
        self.sensorState = packet.sensorState
        self.minutesSinceStart = packet.minutesSinceStart
        self.minutesTillExpire = packet.minutesTillExpire
        self.timestamp = timestamp
    }
    
    public var isStateValid: Bool {
        return glucoseValue >= 39 && sensorState.isValid
    }
    
    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: glucoseValue)
    }
    
    public var startDate: Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    public var lifecycleProgress: DeviceLifecycleProgress? {
        return percentComplete >= 0.5 ? CGMLifecycleProgress(percentComplete: percentComplete) : nil
    }
    
    public var minutesRemaining: Int {
        return minutesTillExpire - minutesSinceStart
    }
    
    public var percentComplete: Double {
        return Double(minutesSinceStart) / Double(minutesTillExpire)
    }
}

// MARK: - Helper Functions
extension SensorReading {
    
    public mutating func calculate(predecessor: SensorReading?, range: DoubleRange) {
        let thresholds: ClosedRange<HKQuantity> = range.quantityRange(for: .milligramsPerDeciliter)
        
        switch self.quantity {
        case _ where self.quantity <= thresholds.lowerBound: glucoseRangeCategory = GlucoseRangeCategory(rawValue: 2)
        case _ where self.quantity >= thresholds.upperBound: glucoseRangeCategory = GlucoseRangeCategory(rawValue: 4)
        default: glucoseRangeCategory = GlucoseRangeCategory(rawValue: 3)
        }
        
        guard let reference = predecessor else { self.trendType = .flat; return }
        
        if self.timestamp != reference.timestamp {
            let differenceGlucose = (Double(reference.glucoseValue) - Double(self.glucoseValue))
            let differenceTimestamp = (Double(reference.timestamp * 1_000) - Double(self.timestamp * 1_000))
            self.trendType = GlucoseTrend(slope: 60_000 * (differenceGlucose / differenceTimestamp))
        }
    }
}

fileprivate func GlucoseTrend(slope: Double) -> GlucoseTrend? {
    switch slope {
    case _ where slope <= (-3.5): return GlucoseTrend(rawValue: 7)
    case _ where slope <= (-2.0): return GlucoseTrend(rawValue: 6)
    case _ where slope <= (-1.0): return GlucoseTrend(rawValue: 5)
    case _ where slope <= (+1.0): return GlucoseTrend(rawValue: 4)
    case _ where slope <= (+2.0): return GlucoseTrend(rawValue: 3)
    case _ where slope <= (+3.5): return GlucoseTrend(rawValue: 2)
    case _ where slope <= (+4.0): return GlucoseTrend(rawValue: 1)
    default: return GlucoseTrend(rawValue: 4)
    }
}

