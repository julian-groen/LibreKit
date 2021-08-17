//
//  Measurement.swift
//  LibreKit
//
//  Created by Julian Groen on 21/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


public struct Measurement {
    
    public var rawGlucose: Int

    public var rawTemperature: Int
    
    public var timestamp: TimeInterval
    
    public var glucose: Double
    
    /// slope to calculate glucose from raw value in (mg/dl)/raw
    private let slope: Double = 0.1
    
    /// optional adjustment to temprature raw value
    private var adjustment: Int = 0
    
    /// glucose offset to be added in mg/dl
    private let offset: Double = 0.0
    
    public init(rawGlucose: Int, rawTemperature: Int) {
        self.rawGlucose = rawGlucose
        self.rawTemperature = rawTemperature
        self.glucose = Double(rawGlucose)
        self.timestamp = TimeInterval()
    }
    
    public init(_ bytes: Data, _ timestamp: TimeInterval, params: AlgorithmParameters) {
        self.timestamp = timestamp
        self.rawTemperature = (Int(bytes[4] & 0x3F) << 8) + Int(bytes[3])
        self.rawGlucose = (Int(bytes[1] & 0x1F) << 8) + Int(bytes[0])
        self.glucose = offset + slope * Double(rawGlucose)
        
        let temperatureAdjustment = (SensorFunctions.read(bytes, 0, 0x26, 0x9) << 2)
        let negativeAdjustment = SensorFunctions.read(bytes, 0, 0x2f, 0x1) != 0
        self.adjustment = negativeAdjustment ? -temperatureAdjustment : temperatureAdjustment
        
        let slope = params.slope_slope * Double(rawTemperature) + params.offset_slope
        let offset = params.slope_offset * Double(rawTemperature) + params.offset_offset
        let temporary = slope * Double(rawGlucose) + offset
        self.glucose = temporary * params.extraSlope + params.extraOffset
    }
    
    public func glucose(calibration: SensorCalibration) -> Double {
        let ca = 0.0009180023
        let cb = 0.0001964561
        let cc = 0.0000007061775
        let cd = 0.00000005283566
        
        let rawTemperature = Double(self.rawTemperature)
        let rawTemperatureAdjustment = Double(self.adjustment)
        let rawGlucose = Double(self.rawGlucose)
        
        let rLeft = rawTemperature * Double(72500)
        let rRight = rawTemperatureAdjustment + calibration.i6
        let logR  = log((rLeft / rRight) - Double(1000))
        
        let d  = pow(logR, 3) * cd + pow(logR, 2) * cc + logR * cb + ca
        let temperature = 1 / d - 273.15
        
        let g1 = 65.0 * (rawGlucose - calibration.i3) / (calibration.i4 - calibration.i3)
        let g2 = pow(1.045, 32.5 - temperature)
        
        let v1 = SensorCalibration.t1[calibration.i2 - 1]
        let v2 = SensorCalibration.t2[calibration.i2 - 1]
        
        return round(((g1 * g2) - v1) / v2)
    }
}

extension Measurement: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### Measurement",
            "* rawGlucose: \(String(describing: rawGlucose))",
            "* rawTemperature: \(String(describing: rawTemperature))",
            "* timestamp: \(String(describing: timestamp))",
            ""
        ].joined(separator: "\n")
    }
}
