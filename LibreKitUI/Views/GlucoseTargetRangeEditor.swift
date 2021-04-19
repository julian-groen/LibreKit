//
//  GlucoseTargetRangeEditor.swift
//  LibreKitUI
//
//  Created by Julian Groen on 12/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit


struct GlucoseTargetRangeEditor: View {
    
    @State var value: DoubleRange
    @State var showingConfirmationAlert = false
    @State var isEditing: Bool = false

    @Environment(\.dismiss) var dismiss
    
    let initialValue: DoubleRange
    let onSave: (_ newValue: DoubleRange) -> Void
    let descriptiveText: String
    let preferredUnit: HKUnit
    
    fileprivate init(value: DoubleRange, onSave save: @escaping (_ newValue: DoubleRange) -> Void,
                     descriptiveText: String, preferredUnit: HKUnit) {
        self.initialValue = value
        self._value = State(initialValue: value)
        self.preferredUnit = preferredUnit
        self.descriptiveText = descriptiveText
        self.onSave = save
    }
    
    public init(viewModel: ManagerSettingsModel, didSave: (() -> Void)? = nil) {
        self.init(
            value: viewModel.glucoseTargetRange,
            onSave: { [weak viewModel] newValue in
                viewModel?.saveGlucoseTargetRange(newValue)
                didSave?()
            },
            descriptiveText: viewModel.bloodglucoseDescription,
            preferredUnit: viewModel.preferredUnit
        )
    }
    
    var body: some View {
        if value == initialValue {
            return AnyView(content
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: EmptyView())
            )
        } else {
            return AnyView(content
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: cancelButton)
            )
        }
    }
    
    private var content: some View {
        ConfigurationPage(
            title: Text("Blood Glucose", comment: "The title text for target range settings"),
            actionButtonTitle: Text("Save", comment: "The button text for saving on a configuration page"),
            actionButtonState: value != initialValue ? .enabled : .disabled,
            cards: {
                Card {
                    DescriptiveText(label: descriptiveText)
                    GlucoseTargetRangeSetting(
                        isEditing: $isEditing,
                        value: $value,
                        preferredUnit: preferredUnit,
                        expanded: {
                            GlucoseRangePicker(
                                range: Binding(
                                    get: {
                                        self.value.quantityRange(for: .milligramsPerDeciliter)
                                    },
                                    set: { newValue in
                                        withAnimation {
                                            self.value = newValue.doubleRange(for: .milligramsPerDeciliter)
                                        }
                                    }
                                ),
                                unit: self.preferredUnit,
                                minValue: self.guardrail.absoluteBounds.lowerBound,
                                maxValue: self.guardrail.absoluteBounds.upperBound,
                                guardrail: self.guardrail
                            )
                        }
                    )
                }
            },
            actionAreaContent: {
                guardrailWarningIfNecessary
            },
            action: {
                if self.crossedThresholds.isEmpty {
                    self.continueSaving()
                } else {
                    self.showingConfirmationAlert = true
                }
            }
        )
        .alert(isPresented: $showingConfirmationAlert, content: confirmationAlert)
        .navigationBarTitle("", displayMode: .inline)
    }
    
    private var guardrail: Guardrail<HKQuantity> {
        return Guardrail.bloodglucoseGuardrail()
    }
    
    private var crossedThresholds: [SafetyClassification.Threshold] {
        let range = value.quantityRange(for: .milligramsPerDeciliter)
        let thresholds: [SafetyClassification.Threshold] = [range.lowerBound, range.upperBound].compactMap { bound in
            switch guardrail.classification(for: bound) {
            case .withinRecommendedRange:
                return nil
            case .outsideRecommendedRange(let threshold):
                return threshold
            }
        }
        return thresholds
    }
    
    private var guardrailWarningIfNecessary: some View {
        let crossedThresholds = self.crossedThresholds
        return Group {
            if crossedThresholds.isEmpty == false {
                BloodGlucoseGuardrailWarning(crossedThresholds: crossedThresholds)
            }
        }
    }
    
    private var cancelButton: some View {
        Button(action: { dismiss() } ) { Text("Cancel", comment: "Cancel editing settings button title") }
    }
    
    private func confirmationAlert() -> SwiftUI.Alert {
        return SwiftUI.Alert(
            title: Text("Save Target Range?", comment: "Alert title for confirming value outside the recommended range"),
            message: Text(TherapySetting.glucoseTargetRange.guardrailSaveWarningCaption),
            primaryButton: .cancel(
                Text("Go Back", comment: "Text for go back action on confirmation alert")
            ),
            secondaryButton: .default(
                Text("Continue", comment: "Text for continue action on confirmation alert"), action: continueSaving
            )
        )
    }
    
    private func continueSaving() {
        self.onSave(self.value)
    }
}

private struct BloodGlucoseGuardrailWarning: View {
    
    var crossedThresholds: [SafetyClassification.Threshold]
    
    var body: some View {
        assert(!crossedThresholds.isEmpty)
        return GuardrailWarning(
            title: title,
            thresholds: crossedThresholds,
            caption: caption
        )
    }

    private var title: Text {
        if crossedThresholds.count == 1 {
            return singularWarningTitle(for: crossedThresholds.first!)
        } else {
            return multipleWarningTitle
        }
    }

    private func singularWarningTitle(for threshold: SafetyClassification.Threshold) -> Text {
        switch threshold {
        case .minimum, .belowRecommended:
            return Text("Low Target Range Value", comment: "Title text for the low target range value warning")
        case .aboveRecommended, .maximum:
            return Text("High Target Range Value", comment: "Title text for the low target range value warning")
        }
    }

    private var multipleWarningTitle: Text {
        return Text("Target Range Values", comment: "Title text for multi-value target range value warning")
    }

    var caption: Text? {
        guard crossedThresholds.allSatisfy({ $0 == .aboveRecommended || $0 == .maximum }) else {
            return nil
        }
        return Text(crossedThresholds.count > 1 ? TherapySetting.glucoseTargetRange.guardrailCaptionForOutsideValues
                        : TherapySetting.glucoseTargetRange.guardrailCaptionForHighValue)
    }
}
