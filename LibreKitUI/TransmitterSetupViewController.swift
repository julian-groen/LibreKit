//
//  TransmitterSetupViewController.swift
//  LibreKitUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import LibreKit
import UIKit
import CoreBluetooth

protocol TransmitterSetupViewControllerDelegate: SetupTableViewControllerDelegate {
    
    func transmitterSetupViewControllerCancelButtonPressed(_ viewController: TransmitterSetupViewController)
    
    func transmitterSetupViewControllerContinueButtonPressed(_ viewController: TransmitterSetupViewController)
}

public class TransmitterSetupViewController: SetupTableViewController, TransmitterSetupManagerDelegate {
    
    private var bluetoothManager: TransmitterSetupManager? = nil
    
    private var peripherals: [CBPeripheral] = [CBPeripheral]() {
        didSet {
            tableView.reloadSections(IndexSet(integer: Section.setup.rawValue), with: .automatic)
        }
    }
    
    public init() {
        super.init(style: .grouped)
        bluetoothManager = TransmitterSetupManager()
        bluetoothManager?.delegate = self
        updateContinueButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        bluetoothManager?.disconnect()
        bluetoothManager?.delegate = nil
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = LibreCGMManager.localizedTitle
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 55
        tableView.register(SetupTableViewHeader.self, forHeaderFooterViewReuseIdentifier: SetupTableViewHeader.className)
        
        UserDefaults.standard.transmitterID = nil
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bluetoothManager?.disconnect()
        bluetoothManager?.delegate = nil
    }
    
    // MARK: - UITableViewDataSource
    
    private enum Section: Int, CaseIterable {
        case setup
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return LocalizedString("Nearby Transmitters", comment: "Section title for nearby transmitters")
    }
    
    override public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SetupTableViewHeader.className)
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AnnotatedTableViewCell<String>(style: .subtitle, reuseIdentifier: nil)
        
        if let peripheral = peripherals[safe: indexPath.row] {
            cell.textLabel?.text = peripheral.name ?? "Unknown device"
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.numberOfLines = 0
            cell.annotation = peripheral.identifier.uuidString
            cell.detailTextLabel?.text = cell.annotation
            cell.isSelected = (UserDefaults.standard.transmitterID == cell.annotation)
        }
        
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AnnotatedTableViewCell<String> {
            guard let transmitterID = cell.annotation else {
                return
            }

            if UserDefaults.standard.transmitterID == transmitterID {
                cell.setSelected(false, animated: false)
                UserDefaults.standard.transmitterID = nil
            } else {
                cell.setSelected(true, animated: false)
                UserDefaults.standard.transmitterID = transmitterID
            }
            updateContinueButton()
        }
    }
    
    // MARK: - TransmitterSetupManagerDelegate
    
    public func transmitterManager(_ peripheral: CBPeripheral?, didDiscoverPeripherals peripherals: [CBPeripheral]) {
        if self.peripherals != peripherals {
            self.peripherals = peripherals
        }
    }
    
    override public func continueButtonPressed(_ sender: Any) {
        if let delegate = delegate as? TransmitterSetupViewControllerDelegate {
            delegate.transmitterSetupViewControllerContinueButtonPressed(self)
        }
    }

    override public func cancelButtonPressed(_: Any) {
        if let delegate = delegate as? TransmitterSetupViewControllerDelegate {
            delegate.transmitterSetupViewControllerContinueButtonPressed(self)
        }
    }
    
    private func updateContinueButton() {
        footerView.primaryButton.isEnabled = (UserDefaults.standard.transmitterID != nil || UserDefaults.standard.debugModeActivated)
    }
    
}
