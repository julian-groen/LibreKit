//
//  Transmitter+Mock.swift
//  LibreKit
//
//  Created by Julian Groen on 27/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth


public class MockTransmitter: Transmitter {
    
    public var name: String = "Transmitter"
    
    public var manufacturer: String = "Mock"
    
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
        return true
    }
    
    public func startConfiguration() { }
}
