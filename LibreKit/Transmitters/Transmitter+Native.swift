//
//  Transmitter+Native.swift
//  LibreKit
//
//  Created by Julian Groen on 15/08/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log

// MARK: - Characteristics
extension NativeTransmitter {
    
    public var serviceCharacteristic: CBUUID { CBUUID(string: "FDE3") }
    
    public var writeCharacteristic: CBUUID { CBUUID(string: "F001") }
    
    public var notifyCharacteristic: CBUUID { CBUUID(string: "F002") }
}

public class NativeTransmitter: Transmitter {
    
    private let log = OSLog(category: "NativeTransmitter")
    
    public var name: String = "Freestyle"
    
    public var manufacturer: String = "Abbott"
    
    public var peripheral: CBPeripheral {
        didSet {
            guard oldValue !== peripheral else { return }
            oldValue.delegate = nil
            peripheral.delegate = self
        }
    }
    
    public weak var delegate: TransmitterDelegate?
    
    public required init(from peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }
    
    public static func supported(_ peripheral: CBPeripheral) -> Bool {
        peripheral.name?.lowercased().starts(with: "abbott") ?? false
    }
    
    public func startConfiguration() {
        peripheral.discoverServices([self.serviceCharacteristic])
    }
}

// MARK: - CBPeripheralDelegate
extension NativeTransmitter: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log.default("%@: %@", #function, String(describing: error))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log.default("%@: %@: %@", #function, service, String(describing: error))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        log.default("%@: %@: %@", #function, characteristic, String(describing: error))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        log.default("%@: %@: %@", #function, characteristic, String(describing: error))
    }
}
