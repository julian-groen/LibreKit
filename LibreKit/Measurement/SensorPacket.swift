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
    
    public init(_ type: SensorType, bytes: Data) {
        self.sensorType = type
        self.debug(bytes)
    }
    
    public init?(rawValue: RawValue) {
        self.init(.libreOne, bytes: Data())
    }
    
    public var rawValue: RawValue {
        return [:]
    }
    
    public func debug(_ bytes: Data) {
        let sensorState = SensorState(byte: bytes[4])
        print(bytes.hexEncodedString().uppercased())
        print((Int(bytes[317] & 0xFF) << 8) + Int(bytes[316] & 0xFF))
        print(sensorType)
        print(sensorState)
    }
}

extension SensorPacket: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### SensorPacket",
            "* sensorType: \(String(describing: sensorType))",
        ].joined(separator: "\n")
    }
}

extension SensorPacket {
    public static func parse(from data: Data, id: Data) -> SensorPacket? {
        let patchInformation = (data.count > 345 ? Data(data[345...350]) : nil)
        let sensorType = SensorType(byte: (data.count > 345 ? data[345] : nil))
        
        var rawSensorData: Data = data
        if (sensorType == .libreTwo || sensorType == .libreUSA) && data.count > 345 {
            rawSensorData = SensorDecrypt.decrypt(id, patchInformation ?? Data(), data)
        }
        
        guard rawSensorData.count == 344 && SensorCRC.parse(data: rawSensorData) else {
            return nil
        }
        return SensorPacket(sensorType, bytes: rawSensorData)
    }
}







extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }

    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars) { result, value in
            result.append(Data.hexAlphabet[Int(value / 16)])
            result.append(Data.hexAlphabet[Int(value % 16)])
        })
    }
}
