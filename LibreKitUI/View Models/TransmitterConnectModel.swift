//
//  TransmitterConnectModel.swift
//  LibreKitUI
//
//  Created by Julian Groen on 08/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import LibreKit


class TransmitterConnectModel: NSObject, ObservableObject {
    
    let cgmManager: LibreCGMManager
    var hasContinued: ((_ cgmManager: LibreCGMManager) -> Void)?
    var hasCancelled: (() -> Void)?
    
    @Published var transmitters: [Transmitter] = []
    
    override init() {
        self.cgmManager = LibreCGMManager(state: LibreCGMManagerState())
        self.cgmManager.transmitterManager.setScanningEnabled(true)
        super.init()
        self.addTransmittersDidChangeObserver()
    }
    
    deinit {
        self.cgmManager.transmitterManager.setScanningEnabled(false)
    }
    
    func connect(_ transmitter: Transmitter) {
        cgmManager.transmitterManager.connect(transmitter)
    }
    
    func disconnect(_ transmitter: Transmitter) {
        cgmManager.transmitterManager.disconnect(transmitter)
    }
    
    private func addTransmittersDidChangeObserver() {
        self.addObserver(selector: #selector(reloadTransmitters), name: .TransmittersDidChange)
    }
    
    private func addObserver(selector: Selector, name: NSNotification.Name?) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    @objc private func reloadTransmitters() {
        cgmManager.transmitterManager.getTransmitters { (transmitters) in
            DispatchQueue.main.async { [weak self] in self?.transmitters = transmitters }
        }
    }
}
