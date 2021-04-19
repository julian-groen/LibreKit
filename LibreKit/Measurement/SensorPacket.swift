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
    
    public var placeholder: Int
    
    public init?(rawValue: RawValue) {
        self.placeholder = 100
    }
    
    public var rawValue: RawValue {
        return [
            "placeholder": placeholder,
        ]
    }
}

extension SensorPacket: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### SensorPacket",
        ].joined(separator: "\n")
    }
}

