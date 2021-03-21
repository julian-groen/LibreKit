//
//  LibreManagerSetupViewController.swift
//  Libre2ClientUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import Libre2Client
import UIKit
import CoreBluetooth

class LibreManagerSetupViewController: UINavigationController, CGMManagerSetupViewController, UINavigationControllerDelegate, CompletionNotifying {
    weak var setupDelegate: CGMManagerSetupViewControllerDelegate?
    weak var completionDelegate: CompletionDelegate?
    
    init() {
        let setupViewController = TransmitterSetupViewController()
        super.init(rootViewController: setupViewController)
        setupViewController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        navigationBar.shadowImage = UIImage()
        navigationBar.prefersLargeTitles = true
        delegate = self
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is SetupTableViewController {
            navigationBar.isTranslucent = false
            navigationBar.shadowImage = UIImage()
        } else {
            navigationBar.isTranslucent = true
            navigationBar.shadowImage = nil
            viewController.navigationItem.largeTitleDisplayMode = .never
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is SetupTableViewController {
            navigationBar.isTranslucent = false
            navigationBar.shadowImage = UIImage()
        } else {
            navigationBar.isTranslucent = true
            navigationBar.shadowImage = nil
        }
    }
}

extension LibreManagerSetupViewController: TransmitterSetupViewControllerDelegate {
    func transmitterSetupViewControllerCancelButtonPressed(_ viewController: TransmitterSetupViewController) {
        completionDelegate?.completionNotifyingDidComplete(self)
    }
    
    func transmitterSetupViewControllerContinueButtonPressed(_ viewController: TransmitterSetupViewController) {
        setupDelegate?.cgmManagerSetupViewController(self, didSetUpCGMManager: Libre2CGMManager())
        completionDelegate?.completionNotifyingDidComplete(self)
    }
    
    func setupTableViewControllerCancelButtonPressed(_ viewController: SetupTableViewController) { }
}
