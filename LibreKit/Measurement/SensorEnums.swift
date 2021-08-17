//
//  SensorEnums.swift
//  LibreKit
//
//  Created by Julian Groen on 20/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


public enum SensorType: Int {
    
    case libreOne = 0
    case libre1A2 = 1
    case libreTwo = 2
    case libreUSA = 3
    case librePro = 4
    
    init(byte: UInt8?) {
        switch byte {
        case 223: self = .libreOne
        case 162: self = .libre1A2
        case 157: self = .libreTwo
        case 229: self = .libreUSA
        case 112: self = .librePro
        default: self = .libreOne
        }
    }
    
    var description: String {
        switch self {
        case .libreOne:
            return "Freestyle Libre 1"
        case .libre1A2:
            return "Freestyle Libre 1 A2"
        case .librePro:
            return "Freestyle Libre Pro H"
        case .libreTwo:
            return "Freestyle Libre 2"
        case .libreUSA:
            return "Freestyle Libre US"
        }
    }
}

public enum SensorState: Int {
    
    case awaiting = 0
    case starting = 1
    case ready    = 2
    case expired  = 3
    case shutdown = 4
    case failure  = 5
    case unknown  = 6
    
    init(byte: UInt8) {
        switch byte {
        case 01: self = .awaiting
        case 02: self = .starting
        case 03: self = .ready
        case 04: self = .expired
        case 05: self = .shutdown
        case 06: self = .failure
        default: self = .unknown
        }
    }
    
    var description: String {
        switch self {
        case .awaiting:
            return "Sensor is not started"
        case .starting:
            return "Sensor in starting phase"
        case .ready:
            return "Sensor is ready"
        case .expired:
            return "Sensor is expired"
        case .shutdown:
            return "Sensor is shut down"
        case .failure:
            return "Sensor has failed"
        default:
            return "Unknown sensor state"
        }
    }
    
    var isValid: Bool {
        return self == .ready
    }
}

public enum SensorError: Error {
    
    case expired
    case invalid
    
    var description: String {
        switch self {
        case .expired:
            return "Sensor has expired"
        case .invalid:
            return "Invalid SensorPacket"
        }
    }
}
