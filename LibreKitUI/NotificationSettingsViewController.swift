//
//  NotificationSettingsViewController.swift
//  LibreKitUI
//
//  Created by Julian Groen on 16/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import LibreKit
import UIKit
import HealthKit

public class NotificationSettingsViewController: UITableViewController {
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizedString("Notifications", comment: "Title describing notifications")

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 55
        
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
    }
    
    @objc private func notificationsEnabledChanged(_ sender: UISwitch) {
        UserDefaults.standard.notificationsEnabled = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.configuration.rawValue), with: .none)
    }
    
    @objc private func lowBatteryNotificationChanged(_ sender: UISwitch) {
        UserDefaults.standard.lowBatteryNotification = sender.isOn
    }
    
    @objc private func sensorExpireNotificationChanged(_ sender: UISwitch) {
        UserDefaults.standard.sensorExpireNotification = sender.isOn
    }
    
    @objc private func noSensorNotificationChanged(_ sender: UISwitch) {
        UserDefaults.standard.noSensorNotification = sender.isOn
    }
    
    @objc private func newSensorNotificationChanged(_ sender: UISwitch) {
        UserDefaults.standard.newSensorNotification = sender.isOn
    }
    
    // MARK: - UITableViewDataSource
    
    private enum Section: Int, CaseIterable {
        case toggle
        case configuration
    }
    
    private enum ConfigurationRow: Int, CaseIterable {
        case lowBattery
        case noSensor
        case sensorExpire
        case newSensor
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .configuration:
            return ConfigurationRow.allCases.count
        case .toggle:
            return 1
        }
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .configuration:
            return LocalizedString("Notification settings", comment: "Section title for notification settings")
        case .toggle:
            return nil
        }
    }
    
    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .configuration:
            return LocalizedString("Determine which notifications will be send as a result of a certain event.", comment: "The footer text for the notification settings section")
        case .toggle:
            return nil
        }
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .toggle:
            let cell = tableView.dequeueIdentifiableCell(cell: SwitchTableViewCell.self, for: indexPath)
            
            cell.textLabel?.text = LocalizedString("Notifications", comment: "Title describing notifications")
            cell.switch?.isOn = UserDefaults.standard.notificationsEnabled ?? false
            cell.switch?.addTarget(self, action: #selector(notificationsEnabledChanged(_:)), for: .valueChanged)
            cell.selectionStyle = .none

            return cell
        case .configuration:
            let cell = tableView.dequeueIdentifiableCell(cell: SwitchTableViewCell.self, for: indexPath)
            cell.switch?.isEnabled = UserDefaults.standard.notificationsEnabled ?? false
            cell.selectionStyle = .none
            
            switch ConfigurationRow(rawValue: indexPath.row)! {
            case .lowBattery:
                cell.textLabel?.text = LocalizedString("Transmitter Battery Low", comment: "The notification title for a low transmitter battery")
                cell.switch?.isOn = UserDefaults.standard.lowBatteryNotification
                cell.switch?.addTarget(self, action: #selector(lowBatteryNotificationChanged(_:)), for: .valueChanged)
            case .sensorExpire:
                cell.textLabel?.text = LocalizedString("Sensor Expiring Soon", comment: "Title text for the button to toggle sensor expire notifications")
                cell.switch?.isOn = UserDefaults.standard.sensorExpireNotification
                cell.switch?.addTarget(self, action: #selector(sensorExpireNotificationChanged(_:)), for: .valueChanged)
            case .noSensor:
                cell.textLabel?.text = LocalizedString("No Sensor Detected", comment: "The notification title for a not detected sensor")
                cell.switch?.isOn = UserDefaults.standard.noSensorNotification
                cell.switch?.addTarget(self, action: #selector(noSensorNotificationChanged(_:)), for: .valueChanged)
            case .newSensor:
                cell.textLabel?.text = LocalizedString("New Sensor Detected", comment: "The notification title for a new detected sensor")
                cell.switch?.isOn = UserDefaults.standard.newSensorNotification
                cell.switch?.addTarget(self, action: #selector(newSensorNotificationChanged(_:)), for: .valueChanged)
            }
            
            return cell
        }
    }

}
