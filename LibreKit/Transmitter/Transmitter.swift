//
//  Transmitter.swift
//  LibreKit
//
//  Created by Julian Groen on 20/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import CoreBluetooth

public let allTransmitters: [Transmitter.Type] = [
    MiaoMiaoTransmitter.self,
    MockTransmitter.self
]

public func InstantiateTransmitter(from peripheral: CBPeripheral) -> Transmitter? {
    guard let transmitterType = peripheral.type() else {
        return nil
    }
    return transmitterType.init(with: peripheral.identifier)
}

public typealias Transmitter = (TransmitterProtocol & AbstractTransmitter)

public protocol TransmitterProtocol {
    
    var name: String { get }
    
    var manufacturer: String { get }
    
    var notifyCharacteristic: [CBUUID] { get }
    
    var serviceCharacteristic: [CBUUID] { get }
    
    var writeCharacteristic: [CBUUID] { get }
    
    func requestData(_ peripheral: CBPeripheral) -> Bool

    func updateValue(_ peripheral: CBPeripheral, value: Data)

    static func supported(_ peripheral: CBPeripheral) -> Bool
}

public class AbstractTransmitter {
    
    var battery: Int?
    
    var identifier: UUID
    
    var characteristic: CBCharacteristic?
    
    var rxBuffer: Data
    
    var resendPacketCounter = 0
    
    var timestampLastPacket: Date
    
    let maxWaitForNextPacket = 60.0
    
    let maxPacketResendRequests = 3
    
    weak var delegate: TransmitterManagerDelegate?
    
    required init(with identifier: UUID) {
        self.identifier = identifier
        self.timestampLastPacket = Date()
        self.rxBuffer = Data()
    }
    
    deinit {
        delegate = nil
    }
    
    func writeValue(_ peripheral: CBPeripheral, value: Data) -> Bool {
        if let characteristic = characteristic {
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
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

class MockTransmitter: Transmitter {
    
    var name: String = "MockTransmitter"
    
    var manufacturer: String = "LibreKit"

    var notifyCharacteristic: [CBUUID] = []

    var serviceCharacteristic: [CBUUID] = []

    var writeCharacteristic: [CBUUID] = []
    
    required init(with identifier: UUID) {
        super.init(with: identifier)
    }
    
    func requestData(_ peripheral: CBPeripheral) -> Bool {
        return false
    }
    
    func updateValue(_ peripheral: CBPeripheral, value: Data) { }
    
    static func supported(_ peripheral: CBPeripheral) -> Bool {
        return true
    }
}
