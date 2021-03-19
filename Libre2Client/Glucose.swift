//
//  Glucose.swift
//  Libre2Client
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
    let wearTimeMinutes: Int
    let state: SensorState
    let date: Date
}

extension Glucose: GlucoseValue {
    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: glucose)
    }
    
    public var startDate: Date {
        return date
    }
}

extension Glucose: SensorDisplayable {
    public var isStateValid: Bool {
        return glucose >= 39 && glucose <= 501
    }
    
    public var sensorAge: String {
        let days  = (wearTimeMinutes / 60) / 24
        let hours = (wearTimeMinutes / 60) - (days * 24)
        return String(format: LocalizedString("%1$@ day(s) and %2$@ hour(s)"), "\(days)", "\(hours)")
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
