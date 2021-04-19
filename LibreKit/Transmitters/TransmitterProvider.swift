//
//  TransmitterDevice.swift
//  LibreKit
//
//  Created by Julian Groen on 27/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth


public let allTransmitters: [Transmitter.Type] = [
    MiaoMiaoTransmitter.self
]

public func TransmitterFromPeripheral(_ peripheral: CBPeripheral) -> Transmitter? {
    guard let transmitterType = peripheral.transmitterType() else {
        return nil
    }
    return transmitterType.init(from: peripheral)
}

public typealias Transmitter = (TransmitterProtocol & AbstractTransmitter)

public protocol TransmitterDelegate: class {
    
    func transmitter(_ transmitter: Transmitter, changedBatteryLevel batteryLevel: Int)
    
    func transmitter(_ transmitter: Transmitter, didRecievePacket packet: SensorPacket)
}

public class AbstractTransmitter: NSObject {
    
    var rxBuffer: Data
    
    var resendPacketCounter: Int = 0
    
    var characteristic: CBCharacteristic?
    
    var timestampLastPacket: Date
    
    let maxWaitForNextPacket = 60.0
    
    let maxPacketResendRequests = 3

    override init() {
        self.timestampLastPacket = Date()
        self.rxBuffer = Data()
    }
    
    func resetDataBuffer() {
        rxBuffer = Data()
        timestampLastPacket = Date()
        resendPacketCounter = 0
    }
}

public protocol TransmitterProtocol: CBPeripheralDelegate {
    
    static func supported(_ peripheral: CBPeripheral) -> Bool
    
    var name: String { get }
    
    var manufacturer: String { get }
    
    var peripheral: CBPeripheral { get set }
    
    var delegate: TransmitterDelegate? { get set }
    
    init(from peripheral: CBPeripheral)
    
    func startConfiguration()
}
