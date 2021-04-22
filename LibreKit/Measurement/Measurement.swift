//
//  Measurement.swift
//  LibreKit
//
//  Created by Julian Groen on 21/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


public struct Measurement {
    
    public var rawValue: [UInt8]
    
    public var rawGlucose: Int {
        return (Int(rawValue[1] & 0x1F) << 8) + Int(rawValue[0])
    }
    
    public var rawTemperature: Int {
        return (Int(rawValue[4] & 0x3F) << 8) + Int(rawValue[3])
    }
    
    public var timestamp: TimeInterval
}

extension Measurement: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### Measurement",
            "* rawValue: \(String(describing: rawValue))",
            "* rawGlucose: \(String(describing: rawGlucose))",
            "* rawTemperature: \(String(describing: rawTemperature))",
            "* timestamp: \(String(describing: timestamp))",
            ""
        ].joined(separator: "\n")
    }
}
