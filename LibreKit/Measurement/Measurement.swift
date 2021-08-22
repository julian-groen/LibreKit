//
//  Measurement.swift
//  LibreKit
//
//  Created by Julian Groen on 21/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


public protocol AbstractMeasurement {
    
    var value: Double { get set }
    var timestamp: TimeInterval { get set }
}

// implementation for usage with derived algorithm
public struct Measurement: AbstractMeasurement {
    
    public var value: Double
    
    public var timestamp: TimeInterval
    
    /// raw temperature value returned from sensor
    private var temperature: Int

    /// raw glucose value returned from sensor
    private var glucose: Int

    /// slope to calculate glucose from raw value in (mg/dl)/raw
    private let slope: Double = 0.1

    /// optional adjustment to temprature raw value
    private var adjustment: Int = 0

    /// glucose offset to be added in mg/dl
    private let offset: Double = 0.0
    
    public init(_ bytes: Data, _ timestamp: TimeInterval, params: AlgorithmParameters) {
        self.timestamp = timestamp
        self.temperature = (Int(bytes[4] & 0x3F) << 8) + Int(bytes[3])
        self.glucose = (Int(bytes[1] & 0x1F) << 8) + Int(bytes[0])
        self.value = offset + slope * Double(glucose)

        let temperature_adjustment = (SensorFunctions.read(bytes, 0, 0x26, 0x9) << 2)
        let negative_adjustment = SensorFunctions.read(bytes, 0, 0x2f, 0x1) != 0
        self.adjustment = negative_adjustment ? -temperature_adjustment : temperature_adjustment

        let slope = params.slope_slope * Double(temperature) + params.offset_slope
        let offset = params.slope_offset * Double(temperature) + params.offset_offset
        let temporary = slope * Double(glucose) + offset
        self.value = temporary * params.extra_slope + params.extra_offset
    }
}

// implementation for usage as math parameter
public struct Placeholder: AbstractMeasurement {
    
    public var value: Double
    
    public var timestamp: TimeInterval
    
    /// raw temperature value returned from sensor
    private var temperature: Double

    /// raw glucose value returned from sensor
    private var glucose: Double
    
    public init(value: Double) { self.init(glucose: value, temperature: 0) }
    
    public init(glucose: Double, temperature: Double) {
        self.glucose     = Double(glucose)
        self.temperature = Double(temperature)
        self.value       = Double(glucose)
        self.timestamp   = TimeInterval()
    }
    
    func calculate(calibration: SensorCalibration) -> Double {
        let ca = 0.0009180023
        let cb = 0.0001964561
        let cc = 0.0000007061775
        let cd = 0.00000005283566

        let log = log(((temperature * Double(72500)) / calibration.i6) - Double(1000))
        let d = pow(log, 3) * cd + pow(log, 2) * cc + log * cb + ca
        let temperature = 1 / d - 273.15
        let g1 = 65.0 * (glucose - calibration.i3) / (calibration.i4 - calibration.i3)
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
            "* timestamp: \(Date(timestamp: timestamp))",
            "* glucoseValue: \(String(describing: value))",
            "* rawTemperature: \(String(describing: temperature))",
            "* rawGlucose: \(String(describing: glucose))",
            ""
        ].joined(separator: "\n")
    }
}
