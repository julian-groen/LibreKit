//
//  GlucoseAlarm.swift
//  LibreKit
//
//  Created by Julian Groen on 18/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import HealthKit

public enum AlarmResult: Int, CaseIterable {
    case none = 0
    case low
    case high

    func isAlarming() -> Bool {
        return rawValue != AlarmResult.none.rawValue
    }
}

enum AlarmValidationStatus {
    case success
    case error(String)
}

class GlucoseAlarm: Codable, CustomStringConvertible {

    var enabled: Bool?
    var threshold: GlucoseThreshold?
    
    public func validateGlucose(_ glucose: Double) -> AlarmResult {
        if enabled == true, let threshold = threshold {
            if let low = threshold.low, glucose <= low {
                return .low
            }
            if let high = threshold.high, glucose >= high {
                return .high
            }
        }
        return .none
    }
    
    public func validateAlarm() -> AlarmValidationStatus {
        if let error = validateThreshold() {
            return error
        }
        return .success
    }
    
    private func validateThreshold() -> AlarmValidationStatus? {
        guard let threshold = self.threshold, let low = threshold.low, let high = threshold.high else {
            return .error("Threshold values not set or some are missing.")
        }
        
        if low == high {
            return .error("Invalid thresholds given, given values are identical.")
        }
        if low > high {
            return .error("Invalid thresholds given, low threshold is set above high threshold.")
        }
        if high < low {
            return .error("Invalid thresholds given, high threshold is set above low threshold.")
        }
        
        return nil
    }
    
    var description: String {
        return "GlucoseAlarm={enabled: \(enabled), threshold: \(threshold)}"
    }
    
}

class GlucoseThreshold: Codable, CustomStringConvertible {
    
    var low: Double?
    var high: Double?
    
    public func setLowTreshold(forUnit unit: HKUnit, threshold: Double) {
        self.low = (unit == HKUnit.millimolesPerLiter ? threshold * 18 : threshold)
    }
    
    public func setHighTreshold(forUnit unit: HKUnit, threshold: Double) {
        self.high = (unit == HKUnit.millimolesPerLiter ? threshold * 18 : threshold)
    }
    
    public func getLowTreshold(forUnit unit: HKUnit) -> Double? {
        guard let treshold = low else {
            return nil
        }
        return (unit == HKUnit.millimolesPerLiter ? (treshold / 18).roundTo(places: 1) : treshold)
    }
    
    public func getHighTreshold(forUnit unit: HKUnit) -> Double? {
        guard let treshold = high else {
            return nil
        }
        return (unit == HKUnit.millimolesPerLiter ? (treshold / 18).roundTo(places: 1) : treshold)
    }
    
    var description: String {
        return "GlucoseThreshold={low: \(low), high: \(high)}"
    }
    
}
