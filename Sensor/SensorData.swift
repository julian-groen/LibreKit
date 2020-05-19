//
//  SensorData.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

public struct SensorData {
    
    private let numberOfBytes = 344
    
    let bytes: Data
    
    let timestamp: TimeInterval
    
    var state: SensorState {
        return SensorState(byte: bytes[4])
    }
    
    var minutes: Int {
        return (Int(bytes[317] & 0xFF) << 8) + Int(bytes[316] & 0xFF)
    }
    
    var isValidSensor: Bool {
        return (bytes.count > 23 ? !bytes[9...23].contains(where: { $0 > 0 }) : false)
    }
    
    var hasValidCRCs: Bool {
        return Crc.parse(data: bytes)
    }

    init?(bytes: Data, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        guard bytes.count == numberOfBytes else {
            return nil
        }
        self.bytes = bytes
        self.timestamp = timestamp
    }
    
    func trend(reversed: Bool = false) -> [Measurement] {
        let nextTrendBlock = Int(bytes[26] & 0xFF)
        var measurements = [Measurement]()

        for index in 0..<16 {
            var i: Int = nextTrendBlock - index - 1
            if i < 0 {
                i += 16
            }
            let startIndex = (i * 6 + 28)
            let measurement = Measurement(bytes: bytes[startIndex..<startIndex + 6], timestamp: timestamp.advanced(by: Double(index * -60)))
            measurements.append(measurement)
        }
        
        return (reversed ? measurements.reversed() : measurements)
    }
    
    func history(reversed: Bool = false) -> [Measurement] {
        let nextHistoryBlock = Int(bytes[27] & 0xFF)
        var measurements = [Measurement]()
        
        for index in 0..<32 {
            var i: Int = nextHistoryBlock - index - 1
            if i < 0 {
                i += 16
            }
            let startIndex = (i * 6 + 124)
            let measurement = Measurement(bytes: bytes[startIndex..<startIndex + 6], timestamp: timestamp.advanced(by: Double(index * -900)))
            measurements.append(measurement)
        }
        
        return (reversed ? measurements.reversed() : measurements)
    }
 
}
