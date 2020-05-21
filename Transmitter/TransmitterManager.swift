//
//  TransmitterManager.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import HealthKit
import os.log

public protocol TransmitterManagerDelegate: class {
    
    /**
     Tells the delegate that the state of pre-selected transmitter did change.

     - parameter transmitter: the possible connected transmitter
     - parameter state: the updated state of connected transmitter
    */
    func transmitterManager(_ transmitter: Transmitter?, didChangeTransmitterState state: TransmitterState)
    
    /**
     Tells the delegate that the transmitter has recieved new sensor data from the Freestyle Libre.
     
     - parameter transmitter: the possible connected transmitter
     - parameter data: the new sensor data recieved from the Freestyle Libre
    */
    func transmitterManager(_ transmitter: Transmitter?, didUpdateSensorData data: SensorData)
}

public protocol TransmitterSetupManagerDelegate: class {
    
    /**
     Tells the delegate that the manager discovered new compatible peripherals.
     
     - parameter peripheral: the new compatible peripheral
     - parameter peripherals: all the discovered compatible peripherals
    */
    func transmitterManager(_ peripheral: CBPeripheral?, didDiscoverPeripherals peripherals: [CBPeripheral])
}

public class TransmitterManager: NSObject {

    public static let log = OSLog(subsystem: "com.librekit.bluetooth", category: "TransmitterManager")
    
    private var manager: CBCentralManager! = nil
    
    weak var delegate: TransmitterManagerDelegate?
    
    private let managerQueue = DispatchQueue(label: "com.librekit.bluetooth.queue", qos: .unspecified)
    
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
        os_log("Did deinit TransmitterManager.", log: TransmitterManager.log, type: .default)
    }
    
    private func scanForTransmitter() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        guard manager.state == .poweredOn else {
            return
        }
        
        manager.scanForPeripherals(withServices: transmitter?.serviceCharacteristics, options: nil)
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
        
        manager.connect(peripheral, options: nil)
        state = .connecting
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

// MARK: - CBCentralManagerDelegate

extension TransmitterManager: CBCentralManagerDelegate {
    
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
        
        guard peripheral.name?.lowercased() != nil, let transmitterID = UserDefaults.standard.transmitterID else {
            return
        }
        
        if peripheral.identifier.uuidString == transmitterID {
            os_log("Did discover selected transmitter %{public}@ with identifier %{public}@.", log: TransmitterManager.log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString))
            connect(peripheral, instantiate: (peripheral.identifier.uuidString != transmitter?.identifier))
        } else {
            os_log("Did not connect to %{public}@ with identifier %{public}@, because another device with identifier %{public}@ was selected.", log: TransmitterManager.log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString), transmitterID)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        os_log("Did connect to selected transmitter %{public}@ with identifier %{public}@.", log: TransmitterManager.log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString))
               
        if manager.isScanning {
            manager.stopScan()
        }
        state = .connected
        
        peripheral.discoverServices(transmitter?.serviceCharacteristics)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if stayConnected {
            reconnect()
        }
        state = .disconnected
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
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
            os_log("Did discover services for peripheral %{public}@ with error %{public}@", log: TransmitterManager.log, type: .error, String(describing: peripheral.name), error)
            return
        }
        
        os_log("Did discover services for peripheral %{public}@.", log: TransmitterManager.log, type: .default, String(describing: peripheral.name))
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([transmitter?.writeCharacteristic, transmitter?.notifyCharacteristic] as? [CBUUID], for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if let error = error?.localizedDescription {
            os_log("Did discover characteristics for service %{public}@ with error %{public}@.", log: TransmitterManager.log, type: .error, String(describing: service.debugDescription), error)
            return
        }
        
        os_log("Did discover characteristics for service %{public}@.", log: TransmitterManager.log, type: .default, String(describing: service.debugDescription))
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.intersection(.notify) == .notify && characteristic.uuid == transmitter?.notifyCharacteristic {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.properties.intersection(.write) == .write && characteristic.uuid == transmitter?.writeCharacteristic {
                    transmitter?.characteristic = characteristic
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        
        if let error = error?.localizedDescription {
            os_log("Did update notification state for characteristic %{public}@ with error %{public}@.", log: TransmitterManager.log, type: .error, String(describing: characteristic.debugDescription), error)
            return
        }

        os_log("Did update notification state for characteristic %{public}@.", log: TransmitterManager.log, type: .default, String(describing: characteristic.debugDescription))
        
        if transmitter?.requestData(peripheral) ?? false {
            state = .notifying
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        if let error = error?.localizedDescription {
            os_log("Did update value for characteristic %{public}@ with error %{public}@.", log: TransmitterManager.log, type: .error, String(describing: characteristic.debugDescription), error)
            return
        }

        os_log("Did update value %{public}@ for characteristic %{public}@.", log: TransmitterManager.log, type: .default, String(characteristic.value.debugDescription), String(describing: characteristic.debugDescription))
        
        if let value = characteristic.value, characteristic.uuid == transmitter?.notifyCharacteristic {
            transmitter?.updateValueForNotifyCharacteristic(peripheral, value: value)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        if let error = error?.localizedDescription {
            os_log("Did write value for characteristic %{public}@ with error %{public}@.", log: TransmitterManager.log, type: .error, String(describing: characteristic.debugDescription), error)
            return
        }

        os_log("Did write value %{public}@ for characteristic %{public}@.", log: TransmitterManager.log, type: .default, String(characteristic.value.debugDescription), String(characteristic.debugDescription))
    }
    
}

public class TransmitterSetupManager: NSObject {

    private var manager: CBCentralManager! = nil
    
    public weak var delegate: TransmitterSetupManagerDelegate?
    
    private var peripherals = [CBPeripheral]()
    
    public override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    deinit {
        delegate = nil
        os_log("Did deinit TransmitterSetupManager.", log: TransmitterManager.log, type: .default)
    }
    
    public func disconnect() {
        if manager.isScanning {
            manager.stopScan()
        }
    }
    
}

// MARK: - CBCentralManagerDelegate

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
        os_log("Did discover peripheral %{public}@ with identifier %{public}@.", log: TransmitterManager.log, type: .default, String(describing: peripheral.name), String(describing: peripheral.identifier.uuidString))
        
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
