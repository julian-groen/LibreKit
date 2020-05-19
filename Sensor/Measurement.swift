//
//  Measurement.swift
//  LibreKit
//
//  Created by Julian Groen on 14/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

public struct Measurement {
    
    let bytes: Data
    
    let timestamp: TimeInterval
    
    var rawGlucose: Int {
        return (Int(bytes[1] & 0x1F) << 8) + Int(bytes[0])
    }
    
    var rawTemperature: Int {
        return (Int(bytes[4] & 0x3F) << 8) + Int(bytes[3])
    }
}
