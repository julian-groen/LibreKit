//
//  Transmitter.swift
//  Libre2Client
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import os

public let allTransmitters: [Transmitter.Type] = [
    Libre2Direct.self
]

public func TransmitterFromPeripheral(_ peripheral: CBPeripheral) -> Transmitter? {
    guard let transmitterType = peripheral.type else {
        return nil
    }

    return transmitterType.init(with: peripheral.identifier.uuidString, name: peripheral.name)
}

public typealias Transmitter = (TransmitterProtocol & TransmitterClass)

public protocol TransmitterProtocol {
    var manufacturer: String { get }

    var serviceCharacteristicsUuid: [CBUUID] { get }
    var writeCharacteristicUuid: CBUUID { get }
    var readCharacteristicUuid: CBUUID { get }
    
    func resetConnection()
    func canConnect() -> Bool
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService)
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)

    static func canSupportPeripheral(_ peripheral: CBPeripheral) -> Bool
}

public class TransmitterClass {
    var logger: Logger = Logger(subsystem: "Libre2Client", category: "Transmitter")
    var identifier: String
    var readCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?
    var rxBuffer: Data
    var resendPacketCounter: Int = 0
    var timestampLastPacket: Date
    let maxWaitForNextPacket = 60.0
    let maxPacketResendRequests = 3
    var sensorType: SensorType?

    weak var delegate: TransmitterManagerDelegate?
    
    required init(with identifier: String, name: String?) {
        self.identifier = identifier
        self.timestampLastPacket = Date()
        self.rxBuffer = Data()
    }
    
    deinit {
        delegate = nil
    }
    
    func writeValueToPeripheral(_ peripheral: CBPeripheral, value: Data, type: CBCharacteristicWriteType) -> Bool {
        if let characteristic = writeCharacteristic {
            peripheral.writeValue(value, for: characteristic, type: type)
            
            return true
        }
        
        return false
    }
    
    func reset() {
        rxBuffer = Data()
        timestampLastPacket = Date()
        resendPacketCounter = 0
        
        logger.log("reset state")
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
