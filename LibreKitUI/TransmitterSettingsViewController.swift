//
//  TransmitterSettingsViewController.swift
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

public class TransmitterSettingsViewController: UITableViewController {
    
    public let cgmManager: LibreCGMManager
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    public init(cgmManager: LibreCGMManager) {
        self.cgmManager = cgmManager
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizedString("Transmitter", comment: "Title text for the button to view transmitter info")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.className)
    }
    
    // MARK: - UITableViewDataSource
    
    private enum Section: Int, CaseIterable {
        case latestConnection
        case transmitterInfo
    }
    
    private enum TransmitterInfoRow: Int, CaseIterable {
        case name
        case identifier
        case manufacturer
        case battery
        case hardware
        case firmware
        case state
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .transmitterInfo:
            return TransmitterInfoRow.allCases.count
        case .latestConnection:
            return 1
       }
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .latestConnection:
            return LocalizedString("Latest Connection", comment: "Section title for latest connection")
        case .transmitterInfo:
            return LocalizedString("Transmitter Info", comment: "Section title for transmitter info")
        }
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .latestConnection:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)
            
            cell.textLabel?.text = LocalizedString("Date", comment: "Title describing date")
            cell.selectionStyle = .none
                       
            if let date = cgmManager.lastConnected {
                cell.detailTextLabel?.text = dateFormatter.string(from: date)
            } else {
                cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
            }
            
            return cell
        case .transmitterInfo:
            let cell = tableView.dequeueIdentifiableCell(cell: SettingsTableViewCell.self, for: indexPath)
            
            switch TransmitterInfoRow(rawValue: indexPath.row)! {
            case .name:
               cell.textLabel?.text = LocalizedString("Name", comment: "Title describing transmitter name")

               if let type = cgmManager.name {
                   cell.detailTextLabel?.text = type
               } else {
                   cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
               }
            case .identifier:
                cell.textLabel?.text = LocalizedString("Identifier", comment: "Title describing transmitter identifier")
                
                if let identifier = cgmManager.identifier {
                    cell.detailTextLabel?.text = identifier
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .manufacturer:
                cell.textLabel?.text = LocalizedString("Manufacturer", comment: "Title describing transmitter manufacturer")

                if let manufacturer = cgmManager.manufacturer {
                    cell.detailTextLabel?.text = manufacturer
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .battery:
                cell.textLabel?.text = LocalizedString("Battery", comment: "Title describing transmitter battery")

                if let battery = cgmManager.battery {
                    cell.detailTextLabel?.text = battery
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .firmware:
                cell.textLabel?.text = LocalizedString("Firmware", comment: "Title describing transmitter firmware")

                if let firmware = cgmManager.firmware {
                    cell.detailTextLabel?.text = firmware
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .hardware:
                cell.textLabel?.text = LocalizedString("Hardware", comment: "Title describing transmitter hardware")

                if let hardware = cgmManager.hardware {
                    cell.detailTextLabel?.text = hardware
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            case .state:
                cell.textLabel?.text = LocalizedString("Status", comment: "Title describing status")
                
                if let state = cgmManager.connection {
                    cell.detailTextLabel?.text = state
                } else {
                    cell.detailTextLabel?.text = SettingsTableViewCell.NoValueString
                }
            }
            cell.selectionStyle = .none
            
            return cell
        }
    }
    
}
