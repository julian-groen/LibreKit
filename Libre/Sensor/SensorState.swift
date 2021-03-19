//
//  SensorState.swift
//  Libre2Client
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

public enum SensorState: String, Codable {
    case notYetStarted = "Sensor not yet startet"
    case starting = "Sensor in starting phase"
    case ready = "Sensor is ready"
    case expired = "Sensor is expired"
    case shutdown = "Sensor is shut down"
    case failure = "Sensor has failure"
    case unknown = "Unknown sensor state"

    init() {
        self = .unknown
    }

    init(bytes: Data) {
        switch bytes[4] {
        case 01:
            self = .notYetStarted
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
