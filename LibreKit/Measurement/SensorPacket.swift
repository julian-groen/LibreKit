//
//  SensorPacket.swift
//  LibreKit
//
//  Created by Julian Groen on 19/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit


public struct SensorPacket: RawRepresentable, Equatable {

    public typealias RawValue = [String: Any]
    
    public var sensorType: SensorType
    
    public var sensorState: SensorState
    
    public var rawSensorData: Data
    
    public var minutesSinceStart: Int
    
    public var minutesTillExpire: Int
    
    public var readingTimestamp: TimeInterval
    
    public var isValidSensor: Bool
    
    public init(_ type: SensorType, bytes: Data) {
        self.sensorType = type
        self.sensorState = SensorState(byte: bytes[4])
        self.minutesSinceStart = Int(bytes[317]) << 8 + Int(bytes[316])
        self.minutesTillExpire = Int(bytes[327]) << 8 + Int(bytes[326])
        self.isValidSensor = !bytes[9...23].contains(where: { $0 > 0 })
        self.readingTimestamp = Date().timeIntervalSince1970
        self.rawSensorData = bytes
    }
    
    public init?(rawValue: RawValue) {
        let valueSensorType = (rawValue["sensorType"] as? Int) ?? -1
        guard let sensorType = SensorType(rawValue: valueSensorType) else {
            return nil
        }
         
        guard let rawSensorData = rawValue["rawSensorData"] as? Data else {
            return nil
        }
        
        self.init(sensorType, bytes: rawSensorData)
        
        if let rtimestamp = rawValue["readingTimestamp"] as? TimeInterval {
            self.readingTimestamp = rtimestamp
        }
    }
    
    public func trend(parameters: AlgorithmParameters, reference: Measurement? = nil) -> [Measurement] {
        let nextTrendBlock = Int(rawSensorData[26] & 0xFF)
        var measurements: [Measurement] = [Measurement]()
        for index in 0 ..< 16 {
            let offset = nextTrendBlock - index - 1
            let start = (offset < 0 ? offset + 16 : offset) * 6 + 28
            let timestamp = readingTimestamp.advanced(by: Double(index * -60))
            if let last = reference?.timestamp, last <= timestamp { continue }
            let bytes = Data(rawSensorData[start ..< (start + 6)])
            let measurement = Measurement(bytes, timestamp, params: parameters)
            measurements.append(measurement)
        }
        return measurements
    }
    
    public func history(parameters: AlgorithmParameters, reference: Measurement? = nil) -> [Measurement] {
        let nextHistoryBlock = Int(rawSensorData[27] & 0xFF)
        var measurements: [Measurement] = [Measurement]()
        for index in 0 ..< 32 {
            let offset = nextHistoryBlock - index - 1
            let start = (offset < 0 ? offset + 32 : offset) * 6 + 124
            let timestamp = readingTimestamp.advanced(by: Double(index * -900))
            if let last = reference?.timestamp, last <= timestamp { continue }
            let bytes = Data(rawSensorData[start ..< (start + 6)])
            let measurement = Measurement(bytes, timestamp, params: parameters)
            measurements.append(measurement)
        }
        return measurements
    }
    
    public var rawValue: RawValue {
        return [
            "sensorType": sensorType.rawValue,
            "readingTimestamp": readingTimestamp.rawValue,
            "rawSensorData": rawSensorData
        ]
    }
}

extension SensorPacket: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### SensorPacket",
            "* sensorType: \(String(describing: sensorType.description))",
            "* sensorState: \(String(describing: sensorState.description))",
            "* minutesSinceStart: \(String(describing: minutesSinceStart))",
            "* minutesTillExpire: \(String(describing: minutesTillExpire))",
            "* readingTimestamp: \(String(describing: readingTimestamp))",
            "* isValidSensor: \(String(describing: isValidSensor))"
        ].joined(separator: "\n")
    }
}

extension SensorPacket {
    public static func parse(from data: Data, serial: Data) -> SensorPacket? {
        let patchInformation = (data.count > 345 ? Data(data[345...350]) : nil)
        let sensorType = SensorType(byte: (data.count > 345 ? data[345] : nil))
        
        var rawSensorData: Data = data
        if (sensorType == .libreTwo || sensorType == .libreUSA) && data.count > 345 {
            rawSensorData = SensorFunctions.decrypt(serial, patchInformation ?? Data(), data)
        }
        guard rawSensorData.count == 344 && RedundancyCheck.parse(data: rawSensorData) else {
            return nil
        }
        return SensorPacket(sensorType, bytes: rawSensorData)
    }
}
