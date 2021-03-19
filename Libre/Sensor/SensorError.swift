//
//  SensorError.swift
//  LibreKit
//
//  Created by Julian Groen on 12/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

public enum SensorError: Error {
    case expired
    case invalid

    public var description: String {
        switch self {
        case .expired:
            return "Sensor has expired"
        case .invalid:
            return "Sensor not supported"
        }
    }
}
