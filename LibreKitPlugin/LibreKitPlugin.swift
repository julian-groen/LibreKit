//
//  LibreKitPlugin.swift
//  LibreKitPlugin
//
//  Created by Julian Groen on 15/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import LoopKitUI
import LibreKit
import LibreKitUI
import os.log

class LibreKitPlugin: NSObject, CGMManagerUIPlugin {
    
    private let log = OSLog(category: "LibreKitPlugin")
    
    public var cgmManagerType: CGMManagerUI.Type? {
        return LibreCGMManager.self
    }
    
    override init() {
        super.init()
        log.default("LibreKitPlugin Instantiated")
    }
}
