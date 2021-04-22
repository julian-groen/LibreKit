//
//  UICoordinator.swift
//  LibreKitUI
//
//  Created by Julian Groen on 01/01/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import LibreKit


class UICoordinator: UINavigationController, CGMManagerSetupViewController, CompletionNotifying, UINavigationControllerDelegate {
    
    var cgmManager: LibreCGMManager?
    var completionDelegate: CompletionDelegate?
    var setupDelegate: CGMManagerSetupViewControllerDelegate?
    let glucoseTintColor: Color
    let guidanceColors: GuidanceColors
    
    init(cgmManager: LibreCGMManager? = nil, glucoseTintColor: Color, guidanceColors: GuidanceColors) {
        self.guidanceColors = guidanceColors
        self.glucoseTintColor = glucoseTintColor
        self.cgmManager = cgmManager
        
        super.init(navigationBarClass: UINavigationBar.self, toolbarClass: UIToolbar.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.prefersLargeTitles = true
        delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let controller = viewController(willShow: (cgmManager == nil ? .setup : .settings))
        setViewControllers([controller], animated: false)
    }
    
    private enum ControllerType: Int, CaseIterable {
        case setup
        case settings
    }
    
    private func viewController(willShow view: ControllerType) -> UIViewController {
        switch view {
        case .setup:
            let model = TransmitterConnectModel()
            model.hasCancelled = { [weak self] in
                self?.notifyCompletion()
            }
            model.hasContinued = { [weak self] manager in
                self?.setupCompletion(manager)
            }
            let view = TransmitterConnectView(viewModel: model)
           
            return viewController(rootView: view)
        case .settings:
            guard let cgmManager = cgmManager else {
                fatalError()
            }
            let model = ManagerSettingsModel(cgmManager: cgmManager)
            model.hasCompleted = { [weak self] in
                self?.notifyCompletion()
            }
            let view = ManagerSettingsView(viewModel: model)

            return viewController(rootView: view)
        }
    }
    
    private func viewController<Content: View>(rootView: Content) -> DismissibleHostingController {
        return DismissibleHostingController(rootView: rootView, glucoseTintColor: glucoseTintColor, guidanceColors: guidanceColors)
    }
    
    private func setupCompletion(_ cgmManager: LibreCGMManager) {
        setupDelegate?.cgmManagerSetupViewController(self, didSetUpCGMManager: cgmManager)
        completionDelegate?.completionNotifyingDidComplete(self)
    }
    
    private func notifyCompletion() {
        completionDelegate?.completionNotifyingDidComplete(self)
    }
}
