//
//  SetupTableViewHeader.swift
//  LibreKitUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import UIKit

public class SetupTableViewHeader: UITableViewHeaderFooterView, IdentifiableClass {
    
    public var spinner = UIActivityIndicatorView()
    
    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(spinner)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView.addSubview(spinner)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 13.0, *) {
            spinner.activityIndicatorViewStyle = .medium
        } else {
            spinner.activityIndicatorViewStyle = .gray
        }
        
        spinner.center.y = textLabel?.center.y ?? 0
        spinner.frame.origin.x = contentView.directionalLayoutMargins.trailing + (textLabel?.frame.width ?? 0) + 20
        spinner.hidesWhenStopped = false;
        spinner.startAnimating()
    }

}
