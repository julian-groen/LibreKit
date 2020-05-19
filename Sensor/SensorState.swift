//
//  SensorState.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//
//  State of the freestyle libre sensor
//
//  - awaiting:      0x01 sensor not yet started
//  - starting:      0x02 sensor is in the starting phase
//  - ready:         0x03 sensor is ready, i.e. in normal operation mode
//  - stateFour:     0x04 state with yet unknown meaning
//  - expired:       0x05 sensor is expired
//  - failure:       0x06 sensor has an error
//  - unknown:       any other state

import Foundation

enum SensorState: String {
    
    case awaiting   = "Awaiting"
    case starting   = "Starting"
    case ready      = "Ready"
    case expired    = "Expired"
    case shutdown   = "Shutdown"
    case failure    = "Failure"
    case unknown    = "Unknown"

    init() {
        self = .unknown
    }
    
    init(byte: UInt8) {
        switch byte {
        case 01:
            self = .awaiting
        case 02:
            self = .starting
        case 03:
            self = .ready
        case 04:
            self = .expired
        case 05:
            self = .shutdown
        case 06:
            self = .failure
        default:
            self = .unknown
        }
    }

}
