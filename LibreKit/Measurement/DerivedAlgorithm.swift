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

public struct AlgorithmParameters: Equatable, Codable {
    
    public var slope_slope: Double
    
    public var slope_offset: Double
    
    public var offset_slope: Double
    
    public var offset_offset: Double
    
    public var extraSlope : Double = 1
    
    public var extraOffset: Double = 0
    
    private var glucoseLowerThreshold: Int = 1000
    
    private var temperatureLowerThreshold: Int = 6000
    
    private var glucoseUpperThreshold: Int = 3000
    
    private var temperatureUpperThreshold: Int = 9000
    
    public init(bytes: Data) {
        let calibration = SensorFunctions.calibrate(bytes)
        let responseb1 = Measurement(rawGlucose: glucoseLowerThreshold, rawTemperature: temperatureLowerThreshold).glucose(calibration: calibration)
        let responseb2 = Measurement(rawGlucose: glucoseUpperThreshold, rawTemperature: temperatureLowerThreshold).glucose(calibration: calibration)
        let slope1 = (responseb2 - responseb1) / (Double(glucoseUpperThreshold) - Double(glucoseLowerThreshold))
        let offset1 = responseb2 - (Double(glucoseUpperThreshold) * slope1)
        let responsef1 = Measurement(rawGlucose: glucoseLowerThreshold, rawTemperature: temperatureUpperThreshold).glucose(calibration: calibration)
        let responsef2 = Measurement(rawGlucose: glucoseUpperThreshold, rawTemperature: temperatureUpperThreshold).glucose(calibration: calibration)
        let slope2 = (responsef2 - responsef1) / (Double(glucoseUpperThreshold) - Double(glucoseLowerThreshold))
        let offset2 = responsef2 - (Double(glucoseUpperThreshold) * slope2)
        self.slope_slope   = (slope1 - slope2) / (Double(temperatureLowerThreshold) - Double(temperatureUpperThreshold))
        self.offset_slope  = (slope1 - (slope_slope * Double(temperatureLowerThreshold)))
        self.slope_offset  = (offset1 - offset2) / (Double(temperatureLowerThreshold) - Double(temperatureUpperThreshold))
        self.offset_offset = (offset2 - (slope_offset * Double(temperatureUpperThreshold)))
    }
}

extension AlgorithmParameters: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### AlgorithmParameters",
            "* slopeslope: \(slope_slope)",
            "* slopeoffset: \(slope_offset)",
            "* offsetoffset: \(offset_offset)",
            "* offsetSlope: \(offset_slope)",
            "* extraSlope: \(extraSlope)",
            "* extraOffset: \(extraOffset)",
            ""
        ].joined(separator: "\n")
    }
}
