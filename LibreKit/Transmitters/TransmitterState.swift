//
//  TransmitterState.swift
//  LibreKit
//
//  Created by Julian Groen on 19/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit


public struct TransmitterState: RawRepresentable, Equatable {
   
    public typealias RawValue = [String: Any]
    
    public var autoConnectID: UUID?
    
    public var connectionState: ConnectionState
    
    public var lastBatteryLevel: Int
    
    public init(autoConnectID: UUID?) {
        self.autoConnectID = autoConnectID
        self.connectionState = .unknown
        self.lastBatteryLevel = 100
    }
    
    public init?(rawValue: RawValue) {
        var autoConnectID: UUID?
        if let rawUUIDString = rawValue["autoConnectID"] as? String {
            autoConnectID = UUID(uuidString: rawUUIDString)
        }

        self.init(autoConnectID: autoConnectID)
        
        if let rbatteryLevel = rawValue["lastBatteryLevel"] as? Int {
            self.lastBatteryLevel = rbatteryLevel
        }
    }
    
    public var rawValue: RawValue {
        var value: [String : Any] = [
            "lastBatteryLevel": lastBatteryLevel
        ]
        
        if let autoConnectID = autoConnectID?.uuidString {
            value["autoConnectID"] = autoConnectID
        }

        return value
    }
}

extension TransmitterState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "### TransmitterState",
            "* autoConnectID: \(String(describing: autoConnectID))",
            "* lastBatteryLevel: \(String(describing: lastBatteryLevel))",
            "* connectionState: \(String(describing: connectionState))"
        ].joined(separator: "\n")
    }
}

