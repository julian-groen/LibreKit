//
//  LibreCGMManager.swift
//  LibreKit
//
//  Created by Julian Groen on 10/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import CoreBluetooth
import HealthKit


public class LibreCGMManager: CGMManager {
    
    public var managerIdentifier: String = "LibreKit"

    public var localizedTitle: String = "Freestyle Libre"
    
    public var providesBLEHeartbeat: Bool = true
    
    public var isOnboarded: Bool = true // No distinction between created and onboarded
    
    public var shouldSyncToRemoteService: Bool = true
    
    public var managedDataInterval: TimeInterval? = nil
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public var displayGlucoseUnit: HKUnit?
    
    public let transmitterManager: TransmitterManager
    
    public private(set) var latestReading: SensorReading?

    public var glucoseDisplay: GlucoseDisplayable? {
        return self.latestReading
    }
    
    public var cgmManagerStatus: CGMManagerStatus {
        return CGMManagerStatus(
            hasValidSensorSession: self.lastSensorPacket?.sensorState.isValid ?? false,
            lastCommunicationDate: Date(timestamp: lastSensorPacket?.readingTimestamp)
        )
    }
    
    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    private let lockedState: Locked<LibreCGMManagerState>

    public var managerState: LibreCGMManagerState {
        return lockedState.value
    }

    public var rawState: RawStateValue {
        return managerState.rawValue
    }

    public init(state: LibreCGMManagerState) {
        self.lockedState = Locked(state)
        self.transmitterManager = TransmitterManager(state.transmitterState)
        self.transmitterManager.delegate = self
    }

    public required convenience init?(rawState: RawStateValue) {
        guard let state = LibreCGMManagerState(rawValue: rawState) else { return nil }
        self.init(state: state)
    }
    
    public func set(_ changes: (_ state: inout LibreCGMManagerState) -> Void) {
        let oldValue: LibreCGMManagerState = managerState
        let newValue = lockedState.mutate { (state) in
            changes(&state)
        }

        if oldValue == newValue { return }

        delegate.notify { (delegate) in
            delegate?.cgmManagerDidUpdateState(self)
        }
    }
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        completion(.noData)
    }
    
    private func process(_ packet: SensorPacket) -> [SensorReading]? {
        let algorithm_parameters: AlgorithmParameters = AlgorithmParameters(bytes: packet.rawSensorData)
        
        var measurements: [Measurement] = [Measurement]()
        measurements.append(contentsOf: packet.trend(parameters: algorithm_parameters, reference: measurements.last))
        SavitzkyGolay.smooth(measurements: &measurements, iterations: 2) // trend smoothing
    
        var history = packet.history(parameters: algorithm_parameters, reference: measurements.last)
        SavitzkyGolay.smooth(measurements: &history); history.remove(at: 0) // history smoothing
        measurements.append(contentsOf: history); measurements.sort(by: { $0.timestamp < $1.timestamp })
    
        var entries: [SensorReading] = [SensorReading]()
        for measurement in measurements {
            var reading = SensorReading(packet, value: measurement.value, timestamp: measurement.timestamp)
            reading.calculate(predecessor: entries.last, range: self.glucoseTargetRange); entries.append(reading)
        }
        return entries
    }

    public var device: HKDevice? {
        return HKDevice(
            name: localizedTitle, manufacturer: "Abbott", model: lastSensorPacket?.sensorType.description,
            hardwareVersion: nil, firmwareVersion: nil, softwareVersion: nil,
            localIdentifier: transmitterState?.autoConnectID?.uuidString, udiDeviceIdentifier: nil
        )
    }

    public var debugDescription: String {
        return [
            "## \(String(describing: type(of: self)))",
            "state: \(String(reflecting: managerState))",
            ""
        ].joined(separator: "\n")
    }
}

// MARK: - TransmitterManagerDelegate
extension LibreCGMManager: TransmitterManagerDelegate {
    
    public func transmitterManager(_ manager: TransmitterManager, stateChange state: TransmitterState) {
        issueAlerts(state, predecessor: self.transmitterState); self.transmitterState = state
    }
    
    public func transmitterManager(_ manager: TransmitterManager, recievedPacket packet: SensorPacket) {
        self.lastSensorPacket = packet; issueExpiredHighlightIfNecessary(packet.sensorState)

        guard packet.isValidSensor else {
            delegate.notify { (delegate) in delegate?.cgmManager(self, hasNew: .unreliableData) }
            return
        }
        
        guard let readings = process(packet), readings.count > 0 else {
            delegate.notify { (delegate) in delegate?.cgmManager(self, hasNew: .noData) }
            return
        }

        let startDate = delegate.call { (delegate) -> Date? in delegate?.startDateToFilterNewData(for: self) }
        let newGlucoseSamples = readings.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {
            reading -> NewGlucoseSample in return NewGlucoseSample(
                date: reading.startDate, quantity: reading.quantity, trend: reading.trendType, isDisplayOnly: false,
                wasUserEntered: false, syncIdentifier: "\(Int(reading.timestamp))", device: device
            )
        }

        delegate.notify { (delegate) in
            delegate?.cgmManager(self, hasNew: newGlucoseSamples.isEmpty ? .noData : .newData(newGlucoseSamples))
        }

        let temporaryReading: SensorReading? = self.latestReading
        self.latestReading = readings.filter({ $0.isStateValid }).max(by: { $0.startDate < $1.startDate })
        issueAlerts(self.latestReading, predecessor: temporaryReading)
    }
}

// MARK: - LibreCGMManager Alerts
extension LibreCGMManager {
    
    private func issueAlert(_ alert: Alert) {
        if notificationAlerts { delegate.notify { (delegate) in delegate?.issueAlert(alert) } }
    }
    
    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
        let identifier = Alert.Identifier(managerIdentifier: managerIdentifier, alertIdentifier: alertIdentifier)
        delegate.notify { (delegate) in delegate?.retractAlert(identifier: identifier) }
    }
    
    private func retractGlucoseAlertIfNecessary() {
        let identifier = Alert.Identifier(managerIdentifier: managerIdentifier, alertIdentifier: "glucose.alert")
        delegate.notify { (delegate) in delegate?.retractAlert(identifier: identifier) }
    }
    
    private func issueAlerts(_ reading: SensorReading?, predecessor: SensorReading?) {
        self.retractGlucoseAlertIfNecessary()
        guard let latestSensorReading = reading else { return }
        self.issueLifecycleAlertIfNecessary(latestSensorReading, predecessor)
        self.issueGlucoseAlertIfNecessary(latestSensorReading, predecessor)
    }
    
    private func issueLifecycleAlertIfNecessary(_ reading: SensorReading, _ predecessor: SensorReading?) {
        guard let previousReading = predecessor else { return }
        
        let description: String
        switch reading.minutesRemaining {
        case let x where (x <= 4320 && previousReading.minutesRemaining >= 4320): // three days
            description = String(format: LocalizedString("Replace sensor in %1$@ days", comment: "Sensor expiring. (1: days)"), "3")
        case let x where (x <= 2880 && previousReading.minutesRemaining >= 2880): // two days
            description = String(format: LocalizedString("Replace sensor in %1$@ days", comment: "Sensor expiring. (1: days)"), "2")
        case let x where (x <= 1440 && previousReading.minutesRemaining >= 1440): // one day
            description = String(format: LocalizedString("Replace sensor in %1$@ day", comment: "Sensor expiring. (1: day)"), "1")
        case let x where (x <= 0720 && previousReading.minutesRemaining >= 0720): // twelve hours
            description = String(format: LocalizedString("Replace sensor in %1$@ hours", comment: "Sensor expiring. (1: hours)"), "12")
        case let x where (x <= 0060 && previousReading.minutesRemaining >= 0060): // one hour
            description = String(format: LocalizedString("Replace sensor in %1$@ hour", comment: "Sensor expiring. (1: hour)"), "1")
        default: return
        }
        
        let content = Alert.Content(title: "Sensor ending soon", body: description, acknowledgeActionButtonLabel: "OK")
        let identifier = Alert.Identifier(managerIdentifier: managerIdentifier, alertIdentifier: "sensor.expire")
        let alert = Alert(identifier: identifier, foregroundContent: content, backgroundContent: content, trigger: .immediate)
        self.issueAlert(alert)
    }
    
    private func issueExpiredHighlightIfNecessary(_ state: SensorState) {
        let status = CGMStatusHighlight(localizedMessage: "expired", imageName: "exclamationmark.circle.fill")
        if state == .expired || state == .shutdown { self.latestReading?.statusHighlight = status }
    }
    
    private func issueGlucoseAlertIfNecessary(_ reading: SensorReading, _ predecessor: SensorReading?) {
        guard reading.glucoseRangeCategory != .normal, let glucoseUnit = displayGlucoseUnit else { return }
        
        let formatter = QuantityFormatter(for: glucoseUnit)
        guard let quantity = formatter.string(from: reading.quantity, for: glucoseUnit) else { return }
        
        let content: Alert.Content
        switch reading.glucoseRangeCategory {
        case .high, .aboveRange:
            let localized: String = LocalizedString("High glucose-alarm ⚠️", comment: "The notification title for a high glucose")
            content = Alert.Content(title: localized, body: "\(quantity) \(reading.trendType?.symbol ?? "?")", acknowledgeActionButtonLabel: "OK")
        case .low, .belowRange:
            let localized: String = LocalizedString("Low glucose-alarm ⚠️", comment: "The notification title for a low glucose")
            content = Alert.Content(title: localized, body: "\(quantity) \(reading.trendType?.symbol ?? "?")", acknowledgeActionButtonLabel: "OK")
        default: return
        }

        let identifier = Alert.Identifier(managerIdentifier: managerIdentifier, alertIdentifier: "glucose.alert")
        let alert = Alert(identifier: identifier, foregroundContent: nil, backgroundContent: content, trigger: .immediate)
        self.issueAlert(alert)
    }
    
    private func issueAlerts(_ state: TransmitterState, predecessor: TransmitterState?) {
        if state.lastBatteryLevel <= 10 && state.lastBatteryLevel != 0 {
            self.latestReading?.statusBadge = CGMStatusBadge(imageName: "bolt.circle.fill")
        } else if state.lastBatteryLevel == 0 {
            let highlight = CGMStatusHighlight(localizedMessage: "battery 0%", imageName: "bolt.circle.fill")
            self.latestReading?.statusHighlight = highlight
        }
    }
}

// MARK: - Wrapped State Variable
extension LibreCGMManager {

    public var transmitterState: TransmitterState? {
        get {
            return managerState.transmitterState
        }
        set {
            set { (state) in state.transmitterState = newValue }
        }
    }

    public var notificationAlerts: Bool {
        get {
            return managerState.notificationAlerts
        }
        set {
            set { (state) in state.notificationAlerts = newValue }
        }
    }

    public var glucoseTargetRange: DoubleRange {
        get {
            return managerState.glucoseTargetRange
        }
        set {
            set { (state) in state.glucoseTargetRange = newValue }
        }
    }

    public var lastSensorPacket: SensorPacket? {
        get {
            return managerState.lastSensorPacket
        }
        set {
            set { (state) in state.lastSensorPacket = newValue }
        }
    }
}

// MARK: - AlertSoundVendor implementation
extension LibreCGMManager {
    public func getSoundBaseURL() -> URL? { return nil }
    public func getSounds() -> [Alert.Sound] { return [] }
}
