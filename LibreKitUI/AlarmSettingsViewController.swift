//
//  AlarmSettingsViewController.swift
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

public class AlarmSettingsViewController: UITableViewController, GlucoseInputTableViewCellDelegate {
    
    private var glucoseUnit: HKUnit
    
    private lazy var glucoseAlarm = UserDefaults.standard.glucoseAlarm ?? GlucoseAlarm()
    
    public init(glucoseUnit: HKUnit) {
        self.glucoseUnit = glucoseUnit
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizedString("Glucose Alarm", comment: "Title describing glucose alarm")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 55
               
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        tableView.register(GlucoseInputTableViewCell.nib(), forCellReuseIdentifier: GlucoseInputTableViewCell.className)
    }
    
    
    @objc private func alarmToggleChanged(_ sender: UISwitch) {
        glucoseAlarm.enabled = sender.isOn
        print("Updated Alarm: \(glucoseAlarm)")
    }
    
    // MARK: - UITableViewDataSource
    
    private enum Section: Int, CaseIterable {
        case toggle
        case configuration
        case sync
    }
    
    private enum ConfigurationRow: Int, CaseIterable {
        case lowGlucose
        case highGlucose
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .configuration:
            return ConfigurationRow.allCases.count
        case .toggle, .sync:
            return 1
       }
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .configuration:
            return LocalizedString("Glucose Thresholds", comment: "Section title for glucose thresholds")
        case .toggle, .sync:
            return nil
        }
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .toggle:
            let cell = tableView.dequeueIdentifiableCell(cell: SwitchTableViewCell.self, for: indexPath)
            
            cell.textLabel?.text = LocalizedString("Glucose Alarm", comment: "Title describing glucose alarm")
            cell.switch?.isOn = glucoseAlarm.enabled ?? false
            cell.switch?.addTarget(self, action: #selector(alarmToggleChanged(_:)), for: .valueChanged)
            cell.selectionStyle = .none
        
            return cell
        case .configuration:
            let cell = tableView.dequeueIdentifiableCell(cell: GlucoseInputTableViewCell.self, for: indexPath)
            
            cell.unit = glucoseUnit.localizedDescription
            cell.delegate = self
            cell.selectionStyle = .none
            
            switch ConfigurationRow(rawValue: indexPath.row)! {
            case .lowGlucose:
                if let threshold = glucoseAlarm.threshold, let glucose = threshold.getLowTreshold(forUnit: glucoseUnit) {
                    cell.value = glucose
                }
                cell.type = .low
            case .highGlucose:
                if let threshold = glucoseAlarm.threshold, let glucose = threshold.getHighTreshold(forUnit: glucoseUnit) {
                    cell.value = glucose
                }
                cell.type = .high
            }
            
            return cell
        case .sync:
            let cell = tableView.dequeueIdentifiableCell(cell: TextButtonTableViewCell.self, for: indexPath)
            
            cell.textLabel?.text = LocalizedString("Save", comment: "Title describing save")
            cell.selectionStyle = .none
            
            return cell
        }
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Section(rawValue: indexPath.section)! == .sync {
            tableView.endEditing(true)
            
            DispatchQueue.main.async {
                let result = self.glucoseAlarm.validateAlarm()
                
                switch result {
                case .success:
                    UserDefaults.standard.glucoseAlarm = self.glucoseAlarm
                case .error(let description):
                    let alert = UIAlertController(title: "Oops", message: "Alarm couldn't be saved: \(description)", preferredStyle: .alert)
                    
                    let action = UIAlertAction(title: "ok", style: .cancel) { (_: UIAlertAction!) in }
                    alert.addAction(action)
                    
                    self.present(alert, animated: true)
                }
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    public func textFieldTableViewCellDidBeginEditing(_ cell: GlucoseInputTableViewCell) { }
    
    public func textFieldTableViewCellDidEndEditing(_ cell: GlucoseInputTableViewCell, value: Double) {
        if glucoseAlarm.threshold == nil {
            glucoseAlarm.threshold = GlucoseThreshold()
        }
        
        if let threshold = glucoseAlarm.threshold, let type = cell.type {
            switch type {
            case .low:
                if value == 0 {
                    threshold.low = nil
                } else {
                    threshold.setLowTreshold(forUnit: glucoseUnit, threshold: value)
                }
            case .high:
                if value == 0 {
                    threshold.high = nil
                } else {
                    threshold.setHighTreshold(forUnit: glucoseUnit, threshold: value)
                }
            }
        }
    }

}
