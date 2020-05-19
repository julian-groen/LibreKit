//
//  GlucoseInputTableViewCell.swift
//  LoopKit
//
//  Created by Nate Racklyeft on 7/13/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit

public protocol GlucoseInputTableViewCellDelegate: class {
    
    func textFieldTableViewCellDidBeginEditing(_ cell: GlucoseInputTableViewCell)
    
    func textFieldTableViewCellDidEndEditing(_ cell: GlucoseInputTableViewCell, value: Double)

    func textFieldTableViewCellDidChangeEditing(_ cell: GlucoseInputTableViewCell)
}

// MARK: - Default Implementations

extension GlucoseInputTableViewCellDelegate {
    public func textFieldTableViewCellDidChangeEditing(_ cell: GlucoseInputTableViewCell) { }
}

public enum GlucoseAlarmType: String {
    case low = "Low"
    case high = "High"
}

public class GlucoseInputTableViewCell: UITableViewCell, UITextFieldDelegate, NibLoadable {
 
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var unitLabel: UILabel!
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
            textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingDidEnd)
            textField.keyboardType = .decimalPad
            textField.placeholder = "glucose"
        }
    }
    
    public weak var delegate: GlucoseInputTableViewCellDelegate?
    
    public var unit: String? {
        get {
            return unitLabel.text
        }
        set {
            unitLabel.text = newValue
        }
    }
    
    public var value: Double = 0 {
        didSet {
            textField.text = numberFormatter.string(from: NSNumber(value: value))
        }
    }
    
    public var type: GlucoseAlarmType? {
        didSet {
            titleLabel.text = type?.rawValue ?? "invalid"
        }
    }

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1

        return formatter
    }()
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        textField.delegate = nil
    }

    @objc private func textFieldEditingChanged() {
        delegate?.textFieldTableViewCellDidChangeEditing(self)
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldTableViewCellDidBeginEditing(self)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        let value = numberFormatter.number(from: textField.text ?? "")?.doubleValue ?? 0
        
        if textField == self.textField {
            self.value = value
        }
        
        delegate?.textFieldTableViewCellDidEndEditing(self, value: value)
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }

        let disallowedCharacterSet = NSCharacterSet(charactersIn: "0123456789,.").inverted
        let acceptableLength = (textField.text?.count ?? 0 < 4)

        return string.rangeOfCharacter(from: disallowedCharacterSet) == nil && acceptableLength
    }
    
}
