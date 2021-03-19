//
//  LibreManagerSettingsViewController.swift
//  Libre2ClientUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import Libre2Client
import UIKit
import HealthKit

public class LibreManagerSettingsViewController: UITableViewController {
    public let cgmManager: Libre2CGMManager
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

    public init(cgmManager: Libre2CGMManager, glucoseUnit: HKUnit, allowsDeletion: Bool) {
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
        case latestReading
        case sensorInfo
        case calibrationInfo
        case configuration
        case rescanNfc
        case delete
    }

    private enum LatestReadingRow: Int, CaseIterable {
        case glucose
        case date
        case trend
    }

    private enum SensorRow: Int, CaseIterable {
        case type
        case id
        case serial
        case region
        case state
        case connection
        case age
    }

    private enum CalibrationRow: Int, CaseIterable {
        case i1
        case i2
        case i3
        case i4
        case i5
        case i6
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return allowsDeletion ? Section.allCases.count : Section.allCases.count - 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .latestReading:
            return LatestReadingRow.allCases.count

        case .sensorInfo:
            return SensorRow.allCases.count

        case .calibrationInfo:
            return CalibrationRow.allCases.count

        case .configuration, .rescanNfc, .delete:
            return 1

        }
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .latestReading:
            return LocalizedString("Latest Reading")

        case .sensorInfo:
            return LocalizedString("Sensor Info")

        case .calibrationInfo:
            return LocalizedString("Calibration Info")

        case .configuration:
            return LocalizedString("Configuration")

        case .rescanNfc:
            return " "

        case .delete:
            return " "

        }
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .latestReading:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch LatestReadingRow(rawValue: indexPath.row)! {
            case .glucose:
                cell.textLabel?.text = LocalizedString("Latest Reading Glucose")

                if let quantity = cgmManager.latestReading?.quantity, let glucose = glucoseFormatter.string(from: quantity, for: glucoseUnit) {
                    cell.detailTextLabel?.text = glucose
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .date:
                cell.textLabel?.text = LocalizedString("Latest Reading Date")

                if let startDate = cgmManager.latestReading?.startDate {
                    cell.detailTextLabel?.text = dateFormatter.string(from: startDate)
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .trend:
                cell.textLabel?.text = LocalizedString("Latest Reading Trend")

                if let trend = cgmManager.latestReading?.trendType {
                    cell.detailTextLabel?.text = trend.localizedDescription
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            }
            cell.selectionStyle = .none

            return cell
        case .sensorInfo:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch SensorRow(rawValue: indexPath.row)! {
            case .id:
                cell.textLabel?.text = LocalizedString("Sensor Id")

                if let transmitterID = UserDefaults.standard.transmitterID {
                    cell.detailTextLabel?.text = transmitterID
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .serial:
                cell.textLabel?.text = LocalizedString("Sensor Serial")

                if let sensorSerial = UserDefaults.standard.sensorSerial {
                    cell.detailTextLabel?.text = sensorSerial
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .connection:
                cell.textLabel?.text = LocalizedString("Sensor Connection")

                if let connection = cgmManager.connection {
                    cell.detailTextLabel?.text = connection
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .age:
                cell.textLabel?.text = LocalizedString("Sensor Age")

                if let sensorAge = cgmManager.latestReading?.sensorAge {
                    cell.detailTextLabel?.text = sensorAge
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .type:
                cell.textLabel?.text = LocalizedString("Sensor Type")

                if let sensorType = UserDefaults.standard.sensorType {
                    cell.detailTextLabel?.text = sensorType.rawValue
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .region:
                cell.textLabel?.text = LocalizedString("Sensor Region")

                if let sensorRegion = UserDefaults.standard.sensorRegion {
                    cell.detailTextLabel?.text = sensorRegion.rawValue
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .state:
                cell.textLabel?.text = LocalizedString("Sensor State")

                if let sensorState = UserDefaults.standard.sensorState {
                    cell.detailTextLabel?.text = sensorState.rawValue
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            }
            cell.selectionStyle = .none

            return cell
        case .calibrationInfo:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)

            switch CalibrationRow(rawValue: indexPath.row)! {
            case .i1:
                cell.textLabel?.text = LocalizedString("Calibration Info i1")

                if let i1 = UserDefaults.standard.sensorCalibrationInfo?.i1 {
                    cell.detailTextLabel?.text = i1.description
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .i2:
                cell.textLabel?.text = LocalizedString("Calibration Info i2")

                if let i2 = UserDefaults.standard.sensorCalibrationInfo?.i2 {
                    cell.detailTextLabel?.text = i2.description
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .i3:
                cell.textLabel?.text = LocalizedString("Calibration Info i3")

                if let i3 = UserDefaults.standard.sensorCalibrationInfo?.i3 {
                    cell.detailTextLabel?.text = i3.description
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .i4:
                cell.textLabel?.text = LocalizedString("Calibration Info i4")

                if let i4 = UserDefaults.standard.sensorCalibrationInfo?.i4 {
                    cell.detailTextLabel?.text = i4.description
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .i5:
                cell.textLabel?.text = LocalizedString("Calibration Info i5")

                if let i5 = UserDefaults.standard.sensorCalibrationInfo?.i5 {
                    cell.detailTextLabel?.text = i5.description
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            case .i6:
                cell.textLabel?.text = LocalizedString("Calibration Info i6")

                if let i6 = UserDefaults.standard.sensorCalibrationInfo?.i6 {
                    cell.detailTextLabel?.text = i6.description
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }

            }
            cell.selectionStyle = .none

            return cell
        case .configuration:
            let cell = tableView.dequeueIdentifiableCell(cell: SwitchTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Upload Readings")
            cell.selectionStyle = .none
            cell.switch?.addTarget(self, action: #selector(glucoseSyncChanged(_:)), for: .valueChanged)
            cell.switch?.isOn = UserDefaults.standard.glucoseSync

            return cell
        case .rescanNfc:
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Rescan NFC")
            cell.textLabel?.textAlignment = .center
            //cell.tintColor = .delete
            cell.isEnabled = true

            return cell

        case .delete:
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)

            cell.textLabel?.text = LocalizedString("Delete CGM")
            cell.textLabel?.textAlignment = .center
            cell.tintColor = .delete
            cell.isEnabled = true

            return cell
        }
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
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
        case .rescanNfc:
            let rescanNfcAlert = UIAlertController(title: LocalizedString("Alert title: Rescan NFC"), message: LocalizedString("Alert message: Rescan NFC"), preferredStyle: UIAlertControllerStyle.alert)

            rescanNfcAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                self.cgmManager.resetConnection()
            }))

            rescanNfcAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(rescanNfcAlert, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case .sensorInfo, .calibrationInfo, .latestReading, .configuration:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

fileprivate extension UIAlertController {
    convenience init(cgmDeletionHandler handler: @escaping () -> Void) {
        self.init(title: nil, message: LocalizedString("Are you sure you want to delete this CGM?"), preferredStyle: .actionSheet)
        addAction(UIAlertAction(title: LocalizedString("Delete CGM"), style: .destructive) { _ in handler() })
        addAction(UIAlertAction(title: LocalizedString("Cancel"), style: .cancel, handler: nil))
    }
}
