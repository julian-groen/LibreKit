//
//  DerivedAlgorithm.swift
//  LibreKit
//
//  Created by Julian Groen on 16/08/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


public struct SensorCalibration: Equatable, Codable {
    
    public var i1: Int
    
    public var i2: Int
    
    public var i3: Double
    
    public var i4: Double
    
    public var i5: Double
    
    public var i6: Double
}

extension Array where Element: AbstractMeasurement {
    
    mutating func smoothen(width filter_width: Int = 5) {
        var filter_width_usage: Int = filter_width
        if filter_width > 5 || filter_width < 2 { filter_width_usage = 5 }
        let coefficients_index: Int = filter_width_usage - 2
        
        guard self.count >= filter_width_usage else { return }
        
        var temporary: [AbstractMeasurement] = [AbstractMeasurement]()
        for element in self { temporary.append(element) }
        for _ in 0 ..< filter_width_usage {
            temporary.insert(Placeholder(value: 0), at: 0)
            temporary.append(Placeholder(value: 0))
        }
    }
}

public class SavitzkyGolay {
    
    public static func smooth(measurements: inout [Measurement]) { }
}

public struct AlgorithmParameters: Equatable, Codable {
    
    public var slope_slope: Double
    
    public var slope_offset: Double
    
    public var offset_slope: Double
    
    public var offset_offset: Double
    
    public var extra_slope : Double = 1
    
    public var extra_offset: Double = 0
    
    public init(bytes: Data) {
        let calibration = SensorFunctions.calibrate(bytes)
        let thresholds = (glucose_lower: 1000, temperature_lower: 6000, glucose_upper: 3000, temperature_upper: 9000)
        
        let responseb1 = Placeholder(raw_glucose: thresholds.glucose_lower, raw_temperature: thresholds.temperature_lower).calculate(calibration: calibration)
        let responseb2 = Placeholder(raw_glucose: thresholds.glucose_upper, raw_temperature: thresholds.temperature_lower).calculate(calibration: calibration)
        let slope1 = (responseb2 - responseb1) / (Double(thresholds.glucose_upper) - Double(thresholds.glucose_lower))
        let offset1 = responseb2 - (Double(thresholds.glucose_upper) * slope1)
        
        let responsef1 = Placeholder(raw_glucose: thresholds.glucose_lower, raw_temperature: thresholds.temperature_upper).calculate(calibration: calibration)
        let responsef2 = Placeholder(raw_glucose: thresholds.glucose_upper, raw_temperature: thresholds.temperature_upper).calculate(calibration: calibration)
        let slope2 = (responsef2 - responsef1) / (Double(thresholds.glucose_upper) - Double(thresholds.glucose_lower))
        let offset2 = responsef2 - (Double(thresholds.glucose_upper) * slope2)
        
        self.slope_slope   = (slope1 - slope2) / (Double(thresholds.temperature_lower) - Double(thresholds.temperature_upper))
        self.offset_slope  = (slope1 - (slope_slope * Double(thresholds.temperature_lower)))
        self.slope_offset  = (offset1 - offset2) / (Double(thresholds.temperature_lower) - Double(thresholds.temperature_upper))
        self.offset_offset = (offset2 - (slope_offset * Double(thresholds.temperature_upper)))
    }
}

extension AlgorithmParameters: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### AlgorithmParameters",
            "* slopeslope: \(slope_slope)",
            "* slopeoffset: \(slope_offset)",
            "* offsetoffset: \(offset_offset)",
            "* offsetslope: \(offset_slope)",
            "* extraslope: \(extra_slope)",
            "* extraoffset: \(extra_offset)",
            ""
        ].joined(separator: "\n")
    }
}
