//
//  Transmitter+MiaoMiao.swift
//  LibreKit
//
//  Created by Julian Groen on 20/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import CoreBluetooth
import os.log

class MiaoMiaoTransmitter: Transmitter {
    
    var name: String = "MiaoMiao"
    
    var manufacturer: String = "Tomato"
    
    var notifyCharacteristic: [CBUUID] = [CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")]

    var serviceCharacteristic: [CBUUID] = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]

    var writeCharacteristic: [CBUUID] = [CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")]
    
    required init(with identifier: UUID) {
        super.init(with: identifier)
        manager_log.default("MiaoMiaoTransmitter Instantiated")
    }
    
    func requestData(_ peripheral: CBPeripheral) -> Bool {
        return false
    }
    
    func updateValue(_ peripheral: CBPeripheral, value: Data) {
        
    }
    
    static func supported(_ peripheral: CBPeripheral) -> Bool {
        return peripheral.name?.lowercased().starts(with: "miaomiao") ?? false
    }
}
