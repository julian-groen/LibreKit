//
//  TransmitterSetupViewModel.swift
//  LibreKitUI
//
//  Created by Julian Groen on 18/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LibreKit
import CoreBluetooth

class TransmitterSetupViewModel: NSObject, ObservableObject {
    
    @Published var transmitters: [CBPeripheral] = []
    
    public var didCancel: (() -> Void)?
    public var didContinue: (() -> Void)?
    
   // private var transmitterManager = TransmitterManager()

    override init() {
        super.init()
//        transmitterManager.discover = true
//        transmitterManager.delegate = self
    }
    
    deinit {
        // transmitterManager.delegate = nil
    }
}

// MARK: - TransmitterManagerDelegate

//extension TransmitterSetupViewModel: TransmitterManagerDelegate {
//    
//    public func transmitterManager(_ peripheral: CBPeripheral, advertisementData: [String : Any]) {
//        DispatchQueue.main.async {
//            self.transmitters.append(peripheral)
//            self.transmitters.removeDuplicates()
//        }
//    }
//}

