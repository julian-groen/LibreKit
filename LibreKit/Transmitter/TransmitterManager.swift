//
//  TransmitterManager.swift
//  LibreKit
//
//  Created by Julian Groen on 14/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log

public let manager_log = OSLog(category: "TransmitterManager")

public enum TransmitterState: String {
    
    case unassigned     = "Unassigned"
    case scanning       = "Scanning"
    case disconnected   = "Disconnected"
    case connecting     = "Connecting"
    case connected      = "Connected"
    case unknown        = "Unknown"
}

public protocol TransmitterManagerDelegate: class {
    
    /**
     Tells the delegate the transmitter has recieved new data from the sensor.
     
     - parameter transmitter: connected transmitter
     - parameter data: recieved data from the sensor
    */
    func transmitterManager(_ transmitter: Transmitter, recievedSensorData data: SensorData)

    /**
     Tells the delegate the manager discovered a new compatible peripheral.
     
     - parameter peripheral: discovered peripheral object
     - parameter advertisementData: advertisement data of the peripheral
    */
    func transmitterManager(_ peripheral: CBPeripheral, advertisementData: [String: Any])
}

public class TransmitterManager: NSObject {
    
    private var manager: CBCentralManager! = nil
    
    private let managerQueue = DispatchQueue(label: "com.librekit.transmitter.queue", qos: .unspecified)
    
    private var stayConnected: Bool = true
    
    public var discover: Bool = false
    
    public weak var delegate: TransmitterManagerDelegate?
    
    public private(set) var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self
        }
    }
    
    public private(set) var transmitter: Transmitter? {
        didSet {
            oldValue?.delegate = nil
            transmitter?.delegate = delegate
        }
    }
    
    public private(set) var state: TransmitterState = .unassigned
    
    override init() {
        super.init()
        managerQueue.sync {
            manager = CBCentralManager(delegate: self, queue: managerQueue, options: nil)
        }
    }
    
    deinit {
        delegate = nil
        transmitter = nil
    }
    
    private func scanForTransmitter() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if manager.state == .poweredOn {
            manager.scanForPeripherals(withServices: transmitter?.serviceCharacteristic, options: nil)
            
            guard let transmitterIdentifier = UserDefaults.standard.transmitterIdentifier, !discover else {
                return
            }
            
            if let peripheral = manager.retrievePeripherals(withIdentifiers: [transmitterIdentifier]).first {
                connect(peripheral, instantiate: true)
            }
        }
    }
    
    private func connect(_ peripheral: CBPeripheral, instantiate: Bool = false) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if manager.isScanning {
            manager.stopScan()
        }
        
        self.peripheral = peripheral
        state = .connecting
        
        if instantiate {
            guard let transmitter = InstantiateTransmitter(from: peripheral) else {
                return
            }
            self.transmitter = transmitter
        }
        manager.connect(peripheral, options: nil)
    }
    
    private func reconnect(delay: Double = 7) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            Thread.sleep(forTimeInterval: delay)
            self?.managerQueue.sync {
                if let peripheral = self?.peripheral {
                    self?.connect(peripheral)
                }
            }
        }
    }
    
    public func disconnect() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        
        managerQueue.sync {
            if manager.isScanning {
                manager.stopScan()
            }
            if let connected = peripheral {
                manager.cancelPeripheralConnection(connected)
            }
        }
        stayConnected = false
    }
}

// MARK: - CBCentralManagerDelegate

extension TransmitterManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
    
        manager_log.default("Did update state of the transmitter manager, current state has identifier: %{public}@", String(central.state.rawValue))
        
        switch central.state {
        case .poweredOn:
            scanForTransmitter()
            state = .scanning
        case .resetting, .poweredOff, .unauthorized, .unknown, .unsupported:
            if central.isScanning {
                central.stopScan()
            }
            state = .disconnected
        @unknown default:
            state = .unknown
        }
    }
    
//    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//        dispatchPrecondition(condition: .onQueue(managerQueue))
//    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        guard let peripheralName = peripheral.name?.lowercased(), peripheral.compatible else {
            return
        }
        
        manager_log.default("Did discover compatible peripheral with the following name: %{public}@", String(peripheralName))
        delegate?.transmitterManager(peripheral, advertisementData: advertisementData)
            
        guard let transmitterIdentifier = UserDefaults.standard.transmitterIdentifier else {
            return
        }
        
        if peripheral.identifier == transmitterIdentifier && !discover {
            connect(peripheral, instantiate: true)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if central.isScanning {
            central.stopScan()
        }
        
        manager_log.default("Did connect to selected transmitter with identifier %{public}@", String(describing: peripheral.identifier.uuidString))
        peripheral.discoverServices(transmitter?.serviceCharacteristic)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        manager_log.error("Did fail to connect with peripheral, this could be a result of the following error: %{public}@", String(error.debugDescription))
        
        if stayConnected {
            reconnect()
        }
        state = .disconnected
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        manager_log.error("Did disconnect with peripheral, this could be a result of the following error: %{public}@", String(error.debugDescription))
        
        if stayConnected {
            reconnect()
        }
        state = .disconnected
    }
}

// MARK: - CBPeripheralDelegate

extension TransmitterManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if let error = error?.localizedDescription {
            manager_log.error("Did not discover services for peripheral, following error occured: %{public}@", error)
            return
        }
        
        manager_log.default("Did discover services for peripheral %{public}@.", String(describing: peripheral.name))
        
        let characteristics = (transmitter?.writeCharacteristic ?? []) + (transmitter?.notifyCharacteristic ?? [])
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(characteristics, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if let error = error?.localizedDescription {
            manager_log.error("Did not discover characteristics for service, following error occured: %{public}@", error)
            return
        }
        
        manager_log.default("Did discover characteristics for service %{public}@.", String(describing: service.debugDescription))
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.properties.intersection(.notify) == .notify && transmitter?.notifyCharacteristic.contains(characteristic.uuid) ?? false {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.properties.intersection(.write) == .write && transmitter?.writeCharacteristic.contains(characteristic.uuid) ?? false {
                transmitter?.characteristic = characteristic
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if let error = error?.localizedDescription {
            manager_log.error("Did not update notification state for characteristic, following error occured: %{public}@", error)
            return
        }
        
        manager_log.default("Did update notification state for characteristic %{public}@.", String(describing: characteristic.debugDescription))
        
        if transmitter?.requestData(peripheral) ?? false {
            state = .connected
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if let error = error?.localizedDescription {
            manager_log.error("Did not update value for characteristic, following error occured: %{public}@.", error)
            return
        }

        manager_log.default("Did update value for characteristic %{public}@.", String(describing: characteristic.debugDescription))
        
        if let value = characteristic.value, transmitter?.notifyCharacteristic.contains(characteristic.uuid) ?? false {
            transmitter?.updateValue(peripheral, value: value)
        }
    }
}

extension TransmitterManagerDelegate {
    
    public func transmitterManager(_ peripheral: CBPeripheral, advertisementData: [String: Any]) { }
    
    public func transmitterManager(_ transmitter: Transmitter, recievedSensorData data: SensorData) { }
}
