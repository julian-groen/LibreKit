//
//  LibreManagerSettingsViewController.swift
//  LibreKitUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import LibreKit
import UIKit
import HealthKit

public class LibreManagerSettingsViewController: UITableViewController {
    
    public let cgmManager: LibreCGMManager
    
    public let glucoseUnit: HKUnit

    public let allowsDeletion: Bool
    
    private lazy var glucoseFormatter: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: glucoseUnit)
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    public init(cgmManager: LibreCGMManager, glucoseUnit: HKUnit, allowsDeletion: Bool) {
        self.cgmManager = cgmManager
        self.glucoseUnit = glucoseUnit
        self.allowsDeletion = allowsDeletion
        super.init(style: .grouped)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        title = cgmManager.localizedTitle

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 55

        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)

        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        navigationItem.setRightBarButton(button, animated: false)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @objc func doneTapped(_ sender: Any) {
        complete()
    }
    
    private func complete() {
        if let nav = navigationController as? SettingsNavigationViewController {
            nav.notifyComplete()
        }
    }
    
    @objc func glucoseSyncChanged(_ sender: UISwitch) {
        UserDefaults.standard.glucoseSync = sender.isOn
    }
    
    // MARK: - UITableViewDataSource
    
    private enum Section: Int, CaseIterable {
        case transmitter
        case latestReading
        case sensorAge
        case configuration
        case services
        case delete
    }
    
    private enum LatestReadingRow: Int, CaseIterable {
        case glucose
        case date
        case trend
        case status
    }
    
    private enum ConfigurationRow: Int, CaseIterable {
        case alarm
        case notifications
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return allowsDeletion ? Section.allCases.count : Section.allCases.count - 1
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .latestReading:
            return LatestReadingRow.allCases.count
        case .configuration:
            return ConfigurationRow.allCases.count
        case .transmitter, .sensorAge, .services, .delete:
            return 1
        }
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .latestReading:
            return LocalizedString("Latest Reading", comment: "Section title for latest glucose reading")
        case .configuration:
            return LocalizedString("Configuration", comment: "Section title for configuration")
        case .services:
            return LocalizedString("Remote Services", comment: "Section title for remote services")
        case .sensorAge, .transmitter:
            return nil
        case .delete:
            return " "
        }
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .transmitter:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)
            
            cell.textLabel?.text = LocalizedString("Transmitter", comment: "Title text for the button to view transmitter info")
            cell.detailTextLabel?.text = UserDefaults.standard.transmitterID
            cell.accessoryType = .disclosureIndicator

            return cell
        case .latestReading:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)
            
            switch LatestReadingRow(rawValue: indexPath.row)! {
            case .glucose:
                cell.textLabel?.text = LocalizedString("Glucose", comment: "Title describing glucose value")
                
                if let quantity = cgmManager.latestReading?.quantity, let glucose = glucoseFormatter.string(from: quantity, for: glucoseUnit) {
                    cell.detailTextLabel?.text = glucose
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .date:
                cell.textLabel?.text = LocalizedString("Date", comment: "Title describing glucose date")
                
                if let startDate = cgmManager.latestReading?.startDate {
                    cell.detailTextLabel?.text = dateFormatter.string(from: startDate)
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .trend:
                cell.textLabel?.text = LocalizedString("Trend", comment: "Title describing glucose trend")
                
                if let trend = cgmManager.latestReading?.trendType {
                    cell.detailTextLabel?.text = trend.localizedDescription
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .status:
                cell.textLabel?.text = LocalizedString("Status", comment: "Title describing sensor status")
                
                if let status = cgmManager.latestReading?.sensorStatus {
                    cell.detailTextLabel?.text = status
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            }
            cell.selectionStyle = .none
            
            return cell
        case .sensorAge:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)
            
            cell.textLabel?.text = LocalizedString("Sensor Age", comment: "Title describing sensor age")
            cell.selectionStyle = .none
            
            if let sensorAge = cgmManager.latestReading?.sensorAge {
                cell.detailTextLabel?.text = sensorAge
            } else {
                cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
            }

            return cell
        case .configuration:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch ConfigurationRow(rawValue: indexPath.row)! {
            case .alarm:
                cell.textLabel?.text = LocalizedString("Glucose Alarm", comment: "Title describing sensor Gluocse Alarm")
                cell.accessoryType = .disclosureIndicator
            
                if let alarm = UserDefaults.standard.glucoseAlarm, alarm.enabled == true {
                    cell.detailTextLabel?.text = SettingsTableViewCell.EnabledString
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.TapToSetString
                }
            case .notifications:
                cell.textLabel?.text = LocalizedString("Notifications", comment: "Title describing notifications")
                cell.accessoryType = .disclosureIndicator
                
                if let enabled = UserDefaults.standard.notificationsEnabled, enabled == true {
                    cell.detailTextLabel?.text = SettingsTableViewCell.EnabledString
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.TapToSetString
                }
            }

            return cell
        case .services:
            let cell = tableView.dequeueIdentifiableCell(cell: SwitchTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Upload Readings", comment: "Title text for the button to toggle remote services")
            cell.selectionStyle = .none
            cell.switch?.addTarget(self, action: #selector(glucoseSyncChanged(_:)), for: .valueChanged)
            cell.switch?.isOn = UserDefaults.standard.glucoseSync
             
            return cell
        case .delete:
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")
            cell.textLabel?.textAlignment = .center
            cell.tintColor = .delete
            cell.isEnabled = true

            return cell
        }
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .transmitter:
            let controller = TransmitterSettingsViewController(cgmManager: cgmManager)
            show(controller, sender: nil)
        case .configuration:
            switch ConfigurationRow(rawValue: indexPath.row)! {
            case .alarm:
                let controller = AlarmSettingsViewController(glucoseUnit: glucoseUnit)
                show(controller, sender: nil)
            case .notifications:
                let controller = NotificationSettingsViewController(style: .grouped)
                show(controller, sender: nil)
            }
        case .delete:
            let controller = UIAlertController() {
                self.cgmManager.notifyDelegateOfDeletion {
                    DispatchQueue.main.async {
                        self.complete()
                    }
                }
            }

            present(controller, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case .sensorAge, .latestReading, .services:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

fileprivate extension UIAlertController {
    convenience init(cgmDeletionHandler handler: @escaping () -> Void) {
        self.init(title: nil, message: LocalizedString("Are you sure you want to delete this CGM?", comment: "Confirmation message for deleting a CGM"), preferredStyle: .actionSheet)
        addAction(UIAlertAction(title: LocalizedString("Delete CGM", comment: "Title text for the button to remove a CGM from Loop"), style: .destructive) { _ in handler() })
        addAction(UIAlertAction(title: LocalizedString("Cancel", comment: "The title of the cancel action in an action sheet"), style: .cancel, handler: nil))
    }
}
