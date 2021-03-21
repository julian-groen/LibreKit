//
//  TransmitterManager.swift
//  Libre2Client
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import HealthKit
import os.log

public protocol TransmitterManagerDelegate: class {
    func transmitterManager(_ transmitter: Transmitter?, didChangeTransmitterState state: TransmitterState)
    func transmitterManager(_ transmitter: Transmitter?, didUpdateSensorData data: SensorData)
}

public protocol TransmitterSetupManagerDelegate: class {
    func transmitterManager(_ peripheral: CBPeripheral?, didDiscoverPeripherals peripherals: [CBPeripheral])
}

// MARK: - TransmitterManager

public class TransmitterManager: NSObject {
    private static let unknownOutput = "-"
    
    private var manager: CBCentralManager! = nil
    private let managerQueue = DispatchQueue(label: "com.libre2client.bluetooth.queue", qos: .unspecified)
    
    weak var delegate: TransmitterManagerDelegate?
    var logger: Logger = Logger(subsystem: "Libre2Client", category: "TransmitterManager")
    
    private var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self
        }
    }
    
    private var stayConnected = true
    
    public private(set) var transmitter: Transmitter? = nil {
        didSet {
            oldValue?.delegate = nil
            transmitter?.delegate = delegate
        }
    }
    
    public private(set) var state: TransmitterState = .unassigned {
        didSet {
            delegate?.transmitterManager(transmitter, didChangeTransmitterState: state)
        }
    }
    
    override init() {
        super.init()
        
        managerQueue.sync {
            self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: nil)
        }
    }
    
    deinit {
        transmitter = nil
        delegate = nil
    }
    
    private func scanForTransmitter() {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        guard manager.state == .poweredOn else {
            return
        }
        
        manager.scanForPeripherals(withServices: transmitter?.serviceCharacteristicsUuid, options: nil) // 
        state = .scanning
    }
    
    private func connect(_ peripheral: CBPeripheral, instantiate: Bool = false) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if manager.isScanning {
            manager.stopScan()
        }
    
        self.peripheral = peripheral
        
        if instantiate {
            guard let transmitter = TransmitterFromPeripheral(peripheral) else {
                return
            }
            
            self.transmitter = transmitter
        }
        
        if self.transmitter?.canConnect() ?? false {
            manager.connect(peripheral, options: nil)
            state = .connecting
        } else {
            reconnect(delay: 30)
        }
    }
    
    private func reconnect(delay: Double = 7) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            Thread.sleep(forTimeInterval: delay)
            
            self?.managerQueue.sync {
                if let peripheral = self?.peripheral  {
                    self?.connect(peripheral)
                }
            }
        }
    }
    
    func disconnect() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))

        managerQueue.sync {
            if manager.isScanning {
                manager.stopScan()
            }
            
            if let connection = peripheral {
                manager.cancelPeripheralConnection(connection)
            }
        }
        
        stayConnected = false
    }
}

// MARK: - Extension TransmitterManager

extension TransmitterManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        switch manager.state {
        case .poweredOff:
            state = .powerOff
        case .poweredOn:
            scanForTransmitter()
        default:
            if manager.isScanning {
                manager.stopScan()
            }
            state = .unassigned
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Discover: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        guard peripheral.name?.lowercased() != nil, let transmitterID = UserDefaults.standard.transmitterID else {
            return
        }
        
        if peripheral.identifier.uuidString == transmitterID {
            connect(peripheral, instantiate: (peripheral.identifier.uuidString != transmitter?.identifier))
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Connect: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        state = .connected
        peripheral.discoverServices(transmitter?.serviceCharacteristicsUuid)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Fail to Connect: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        guard let transmitterID = UserDefaults.standard.transmitterID else {
            return
        }
        
        if peripheral.identifier.uuidString == transmitterID {
            manager.connect(peripheral, options: nil)
            state = .connecting
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Disconnect Peripheral: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        guard let transmitterID = UserDefaults.standard.transmitterID else {
            return
        }
        
        if peripheral.identifier.uuidString == transmitterID {
            manager.connect(peripheral, options: nil)
            state = .connecting
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Discover Services: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        transmitter?.peripheral(peripheral, didDiscoverServices: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Discover Characteristics: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        transmitter?.peripheral(peripheral, didDiscoverCharacteristicsFor: service)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Update Notification State: \(peripheral.name ?? TransmitterManager.unknownOutput)")
        
        state = .notifying
        transmitter?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Update Value: \(peripheral.name ?? TransmitterManager.unknownOutput)")

        transmitter?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        logger.debug("Write Value: \(peripheral.name ?? TransmitterManager.unknownOutput)")

        transmitter?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }
}

// MARK: - TransmitterSetupManager

public class TransmitterSetupManager: NSObject {
    private var manager: CBCentralManager! = nil
    private var peripherals = [CBPeripheral]()
    
    public weak var delegate: TransmitterSetupManagerDelegate?
    
    public override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    deinit {
        delegate = nil
    }
    
    public func disconnect() {
        if manager.isScanning {
            manager.stopScan()
        }
    }
    
}

// MARK: - Extension TransmitterSetupManager

extension TransmitterSetupManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if manager.state == .poweredOn && !manager.isScanning {
                manager.scanForPeripherals(withServices: nil, options: nil)
            }
        default:
            return
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard peripheral.name?.lowercased() != nil else {
            return
        }
        
        if peripheral.compatible == true || UserDefaults.standard.debugModeActivated {
            peripherals.append(peripheral)
            peripherals.removeDuplicates()
            
            delegate?.transmitterManager(peripheral, didDiscoverPeripherals: peripherals)
        }
    }
}
