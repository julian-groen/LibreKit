//
//  Glucose.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit

public struct Glucose {
    
    let glucose: Double
    
    var trend: GlucoseTrend
    
    let minutes: Int
    
    let state: SensorState
    
    let timestamp: TimeInterval
}

extension Glucose: GlucoseValue {
    
    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: glucose)
    }
    
    public var startDate: Date {
        return Date(timeIntervalSince1970: timestamp)
    }
}

extension Glucose: SensorDisplayable {
    
    public var isStateValid: Bool {
        return glucose >= 39
    }
    
    public var sensorAge: String {
        let days  = (minutes / 60) / 24
        let hours = (minutes / 60) - (days * 24)
        return String(format: LocalizedString("%1$@ day(s) and %2$@ hour(s)", comment: "Title describing sensor age. (1: day left, 2: hours left)"), days, hours)
    }
    
    public var sensorStatus: String {
        return state.rawValue
    }
    
    public var trendType: GlucoseTrend? {
        return trend
    }
    
    public var isLocal: Bool {
        return true
    }
}
