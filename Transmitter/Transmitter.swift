//
//  Transmitter.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth

public let allTransmitters: [Transmitter.Type] = [
    MiaoMiaoTransmitter.self
]

public func TransmitterFromPeripheral(_ peripheral: CBPeripheral) -> Transmitter? {
    guard let transmitterType = peripheral.type else {
        return nil
    }
    return transmitterType.init(with: peripheral.identifier.uuidString)
}

public typealias Transmitter = (TransmitterProtocol & TransmitterClass)

public protocol TransmitterProtocol {
    
    var name: String { get }
    
    var manufacturer: String { get }
    
    var notifyCharacteristic: CBUUID { get }
    
    var serviceCharacteristics: [CBUUID] { get }
    
    var writeCharacteristic: CBUUID { get }
    
    func requestData(_ peripheral: CBPeripheral) -> Bool

    func updateValueForNotifyCharacteristic(_ peripheral: CBPeripheral, value: Data)

    static func canSupportPeripheral(_ peripheral: CBPeripheral) -> Bool
}

public class TransmitterClass {
    
    var identifier: String
    
    var hardware: String?
    
    var firmware: String?
    
    var battery: Int?
    
    var characteristic: CBCharacteristic?
    
    var rxBuffer: Data
    
    var resendPacketCounter: Int = 0
    
    var timestampLastPacket: Date
    
    let maxWaitForNextPacket = 60.0
    
    let maxPacketResendRequests = 3

    weak var delegate: TransmitterManagerDelegate?
    
    required init(with identifier: String) {
        self.identifier = identifier
        self.timestampLastPacket = Date()
        self.rxBuffer = Data()
    }
    
    deinit {
        delegate = nil
    }
    
    func writeValueToPeripheral(_ peripheral: CBPeripheral, value: Data, type: CBCharacteristicWriteType) -> Bool {
        if let characteristic = characteristic {
            peripheral.writeValue(value, for: characteristic, type: type)
            return true
        }
        return false
    }
    
    func reset() {
        rxBuffer = Data()
        timestampLastPacket = Date()
        resendPacketCounter = 0
    }
}

public enum TransmitterState: String {
    
    case unassigned     = "Unassigned"
    case scanning       = "Scanning"
    case disconnected   = "Disconnected"
    case connecting     = "Connecting"
    case connected      = "Connected"
    case notifying      = "Notifying"
    case powerOff       = "Power Off"
    case unknown        = "Unknown"
}
