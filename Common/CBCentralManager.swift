//
//  CBCentralManager.swift
//  LibreKit
//
//  Created by Julian Groen on 06/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import CoreBluetooth


// MARK: - It's only valid to call these methods on the central manager's queue
extension CBCentralManager {
    func connectIfNecessary(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
        guard case .poweredOn = state else {
            return
        }

        switch peripheral.state {
        case .connected:
            delegate?.centralManager?(self, didConnect: peripheral)
        case .connecting, .disconnected, .disconnecting:
            fallthrough
        @unknown default:
            connect(peripheral, options: options)
        }
    }

    func cancelPeripheralConnectionIfNecessary(_ peripheral: CBPeripheral) {
        guard case .poweredOn = state else {
            return
        }

        switch peripheral.state {
        case .disconnected:
            delegate?.centralManager?(self, didDisconnectPeripheral: peripheral, error: nil)
        case .connected, .connecting, .disconnecting:
            fallthrough
        @unknown default:
            cancelPeripheralConnection(peripheral)
        }
    }
}

public enum ConnectionState: Int {
    
    case unassigned     = 0
    case scanning       = 1
    case disconnected   = 2
    case connecting     = 3
    case connected      = 4
    case powerOff       = 5
    case unknown        = 6
    
    public var description: String {
        switch self {
        case .unassigned:
            return "Unassigned"
        case .scanning:
            return "Scanning"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .unknown:
            return "Unknown"
        case .powerOff:
            return "Power Off"
        }
    }
}
