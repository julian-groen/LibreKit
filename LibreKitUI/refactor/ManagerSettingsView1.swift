//
//  ManagerSettingsView.swift
//  LibreKitUI
//
//  Created by Julian Groen on 16/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit

struct ManagerSettingsView1<Model>: View where Model: ManagerSettingsViewModel {
    
    @State var showingDeleteConfirmation = false
       
    @Environment(\.glucoseTintColor) var glucoseTintColor
    @Environment(\.guidanceColors) var guidanceColors
    
    @ObservedObject var viewModel: Model
 
    var body: some View {
        List {
            overviewSection
            activitySection
            notificationSection
            glucoserangeSection
            deletionSection
        }
        .insetGroupedListStyle()
        .navigationBarTitle(Text("FreeStyle Libre", comment: "FreeStyle Libre"))
        .navigationBarItems(trailing: dismissButton)
    }
    
    // TODO: viewmodel variable
    var overviewSection: some View {
        Section(header: Spacer()) {
            LazyVStack {
                VStack(alignment: .center) {
                    Image(uiImage: UIImage(named: "FreeStyle Libre") ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: ContentMode.fit)
                        .frame(height: 85)
                }.frame(maxWidth: .infinity)
                
                VStack(spacing: 10) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("Sensor expires in")
                            .foregroundColor(.secondary)
                        Spacer()
                        VariableView(value: 13, unit: "days")
                    }
                    ProgressView(progress: CGFloat(0.1)).accentColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Image(systemName: "battery.100")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                            .padding(.leading, -3)
                        VariableView(value: 94, unit: "%")
                        Spacer()
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                        Text("Unknown")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                    }
                }
            }.padding([.top, .bottom], 8)
        }
    }
    
    var activitySection: some View {
        Section(header: SectionHeader(label: "Activity")) {
            LabeledValueView(label: LocalizedString("Glucose", comment: "Title describing glucose"), value: nil)
            LabeledValueView(label: LocalizedString("Last Reading", comment: "Title describing last reading"), value: nil)
            LabeledValueView(label: LocalizedString("Trend", comment: "Title describing glucose trend"), value: nil)
        }
    }
    
    let millimolesPerLiter: HKUnit = {
        return HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
    }()
    
    var notificationSection: some View {
        SectionWithDescriptio(
            header:  SectionHeader(label: "Configuration"),
            title: "Notifications",
            description: "When enabled notifications will be send on certain events. These events consist of blood sugar alerts, low battery warnings and sensor lifetime updates.",
            content: {
                Text("Disable Notifications", comment: "")
                            .foregroundColor(guidanceColors.critical)
                
                
            }
        )
    }
    
    var glucoserangeSection: some View {
        SectionWithDescriptio(
            header: EmptyView(),
            title: "Blood Sugar",
            description: "Specify the blood sugar level range that you want to aim for, based on this range notifications will be send when the glucose level reaches outside of the specified range.",
            content: {
//                ExpandableSetting(
//                    isEditing: .constant(false),
//                    leadingValueContent: {
//                        HStack {
//                            Text("Target")
//                        }
//                    },
//                    trailingValueContent: {
////                        GuardrailConstrainedQuantityRangeView(
////                            range: nil,
////                            unit: millimolesPerLiter,
////                            guardrail: .suspendThreshold,
////                            isEditing: false
////                        )
//                    },
//                    expandedContent: {
//                        HStack {
//                            Text("Test")
//                        }
//                    }
//                )
                Text("Test")
                // GlucoseTargetRangeEditor(isEditing: .constant(true), unit: .millimolesPerLiter)
            }
        )
    }
    
    var deletionSection: some View {
        Section(header: Spacer()) {
            Button(action: {
                showingDeleteConfirmation = true
            }, label: {
                HStack {
                    Spacer()
                    Text("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")
                        .foregroundColor(guidanceColors.critical)
                    Spacer()
                }
            }).actionSheet(isPresented: $showingDeleteConfirmation) {
                deleteConfirmationActionSheet
            }
        }
    }
    
    var deleteConfirmationActionSheet: ActionSheet {
        ActionSheet(title: Text("Are you sure you want to delete this CGM?", comment: "Confirmation message for deleting a CGM"), buttons: [
            .destructive(Text("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")) { viewModel.notifyDeletion() },
            .cancel()
        ])
    }
    
    var dismissButton: some View {
        Button(action: { viewModel.completion?() }) { Text("Done").bold() }
    }

//                GuardrailConstrainedQuantityView(
//                    value: nil,
//                    unit: .millimolesPerLiter,
//                    guardrail: .suspendThreshold,
//                    isEditing: false,
//                    // Workaround for strange animation behavior on appearance
//                    forceDisableAnimations: true
//                )

}

fileprivate struct VariableView: View {
    var value: Int
    var unit: String

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(String(value))
                .font(.system(size: 28))
                .fontWeight(.heavy)
            Text(unit)
                .foregroundColor(.secondary)
        }
    }
}

fileprivate struct SectionWithDescriptio<Header, Content>: View where Header: View, Content: View  {
    let header: Header
    let title: String
    let description: String
    let content: () -> Content

    var body: some View {
        Section(header: header) {
            VStack(alignment: .leading) {
                Spacer()
                Text(title).bold()
                Spacer()
                ZStack(alignment: .leading) {
                    DescriptiveText(label: description)
                }
                Spacer()
            }
            content()
        }
        .contentShape(Rectangle())
    }
}

//#if DEBUG
//struct ManagerSettingsView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        NavigationView {
//            ManagerSettingsView(viewModel: ManagerSettingsViewModel())
//        }
//        // .preferredColorScheme(.dark)
//    }
//}
//#endif
