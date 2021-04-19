//
//  ManagerSettingsViewModel.swift
//  LibreKitUI
//
//  Created by Julian Groen on 16/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LibreKit
import HealthKit

class ManagerSettingsViewModel: NSObject, ObservableObject {
    
    let cgmManager: LibreCGMManager
    
    var completion: (() -> Void)?
    
    init(cgmManager: LibreCGMManager) {
        self.cgmManager = cgmManager
    }
    
    func notifyDeletion() {
        cgmManager.notifyDelegateOfDeletion {
            DispatchQueue.main.async {
                self.completion?()
            }
        }
    }

//    #if DEBUG
//    override convenience init() {
//        self.init(cgmManager: LibreCGMManager())
//    }
//    #endif
}
