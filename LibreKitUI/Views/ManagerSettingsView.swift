//
//  ManagerSettingsView.swift
//  LibreKitUI
//
//  Created by Julian Groen on 12/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit


struct ManagerSettingsView<Model>: View where Model: ManagerSettingsModel {
    
    @ObservedObject var viewModel: Model
    
    @Environment(\.glucoseTintColor) var glucoseTintColor
    @Environment(\.guidanceColors) var guidanceColors
    
    @State var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            overviewSection
            activitySection
            notificationSection
            bloodglucoseSection
            deletionSection
        }
        .insetGroupedListStyle()
        .navigationBarTitle(Text("FreeStyle Libre", comment: "FreeStyle Libre"))
        .navigationBarItems(trailing: dismissButton)
    }
    
    var overviewSection: some View {
        Section(header: Spacer()) {
            LazyVStack {
                VStack(alignment: .center) {
                    Image(uiImage: UIImage(named: "FreeStyle Libre") ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: ContentMode.fit)
                        .frame(height: 85)
                }.frame(maxWidth: .infinity)
                
                lifecycleSection
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Image(systemName: "battery.100")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                            .padding(.leading, -3)
                        unitView(value: viewModel.lastBatteryLevel, unit: "%")
                        Spacer()
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                        Text(viewModel.connectionState.description)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                    }
                }
            }.padding(.vertical, 8)
        }
    }
    
    var activitySection: some View {
        Section(header: SectionHeader(label: "Activity")) {
            LabeledGlucoseView(
                label: LocalizedString("Glucose", comment: "Title describing glucose reading"),
                glucose: viewModel.latestReading?.quantity,
                preferredUnit: viewModel.preferredUnit,
                unitFormatter: viewModel.unitFormatter
            )
            LabeledDateView(
                label: LocalizedString("Date", comment: "Title describing reading date"),
                date: viewModel.latestReading?.startDate,
                dateFormatter: viewModel.dateFormatter
            )
            LabeledValueView(
                label: LocalizedString("Trend", comment: "Title describing glucose trend"),
                value: viewModel.latestReading?.trendType?.localizedDescription
            )
        }
    }
    
    var lifecycleSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("Sensor expires in").foregroundColor(.secondary)
                Spacer()
                switch (viewModel.minutesRemaining) {
                case let minutes? where minutes >= 1440:
                    let days: Int = Int(round(Double(minutes) / 1440))
                    unitView(value: days, unit: days == 1 ?
                                    LocalizedString("day", comment: "Unit for singular day in sensor life remaining") :
                                    LocalizedString("days", comment: "Unit for plural days in sensor life remaining"))
                case let minutes? where minutes >= 60:
                    let hours: Int = Int(round(Double(minutes) / 60))
                    unitView(value: hours, unit: hours == 1 ?
                                    LocalizedString("hour", comment: "Unit for singular hour in sensor life remaining") :
                                    LocalizedString("hours", comment: "Unit for plural hours in sensor life remaining"))
                case let minutes? where minutes < 60:
                    unitView(value: minutes, unit: minutes == 1 ?
                                    LocalizedString("minute", comment: "Unit for singular minute in sensor life remaining") :
                                    LocalizedString("minutes", comment: "Unit for plural minutes in sensor life remaining"))
                default:
                    unitView(value: nil, unit: LocalizedString("days", comment: "Unit for plural days in sensor life remaining"))
                }
            }
            ProgressView(progress: CGFloat(viewModel.latestReading?.percentComplete ?? 0.0)).accentColor(.blue)
        }
    }
 
    var notificationSection: some View {
        SectionWithDescription(
            header: SectionHeader(label: "Configuration"),
            title: LocalizedString("Notifications", comment: ""),
            descriptiveText: viewModel.notificationDescription,
            content: {
                Button(action: {
                    viewModel.toggleNotifications()
                }, label: {
                    if viewModel.alarmNotifications {
                        Text("Disable Notifications", comment: "").foregroundColor(guidanceColors.critical)
                    } else {
                        Text("Enable Notifications", comment: "").foregroundColor(.blue)
                    }
                })
            }
        )
    }
    
    var bloodglucoseSection: some View {
        SectionWithTapToEdit(
            isEnabled: true,
            header: EmptyView(),
            title: LocalizedString("Blood Glucose", comment: "The title text for target range settings"),
            descriptiveText: viewModel.bloodglucoseDescription,
            destination: { dismiss in
                AnyView(
                    GlucoseTargetRangeEditor(viewModel: self.viewModel, didSave: dismiss)
                ).environment(\.dismiss, dismiss)
            },
            content: {
                GlucoseTargetRangeItem(value: viewModel.glucoseTargetRange, preferredUnit: viewModel.preferredUnit)
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
        Button(action: { viewModel.hasCompleted?() }) { Text("Done").bold() }
    }
    
    func unitView(value: Int?, unit: String) -> some View {
        return HStack(alignment: .lastTextBaseline) {
            Text(value == nil ? "-" : String(value ?? 0))
                .font(.system(size: 28))
                .fontWeight(.heavy)
            Text(unit).foregroundColor(.secondary)
        }
    }
}

struct SectionWithTapToEdit<Header, Content, NavigationDestination>: View where Header: View, Content: View, NavigationDestination: View  {
    let isEnabled: Bool
    let header: Header
    let title: String
    let descriptiveText: String
    let destination: (_ goBack: @escaping () -> Void) -> NavigationDestination
    let content: () -> Content

    @State var isActive: Bool = false
    
    private func onFinish() {
        // Dispatching here fixes an issue on iOS 14.2 where schedule editors do not dismiss. It does not fix iOS 14.0 and 14.1
        DispatchQueue.main.async {
            self.isActive = false
        }
    }

    public var body: some View {
        Section(header: header) {
            VStack(alignment: .leading) {
                Spacer()
                Text(title).bold()
                Spacer()
                ZStack(alignment: .leading) {
                    DescriptiveText(label: descriptiveText).padding(.trailing, 10)
                    if isEnabled {
                        NavigationLink(destination: destination(onFinish), isActive: $isActive) { EmptyView() }
                    }
                }
                Spacer()
            }
            content()
        }
        .contentShape(Rectangle()) // make the whole card tappable
        .highPriorityGesture(
            TapGesture().onEnded { _ in
                self.isActive = true
            }
        )
    }
}

struct SectionWithDescription<Header, Content>: View where Header: View, Content: View {
    let header: Header
    let title: String
    let descriptiveText: String
    let content: () -> Content

    var body: some View {
        Section(header: header) {
            VStack(alignment: .leading) {
                Spacer()
                Text(title).bold()
                Spacer()
                ZStack(alignment: .leading) {
                    DescriptiveText(label: descriptiveText)
                }
                Spacer()
            }
            content()
        }
        .contentShape(Rectangle())
    }
}

struct LabeledGlucoseView: View {
    var label: String
    var glucose: HKQuantity?
    var preferredUnit: HKUnit
    var unitFormatter: QuantityFormatter
        
    private var glucoseString: String? {
        guard let glucose = self.glucose else { return nil }
        return unitFormatter.string(from: glucose, for: preferredUnit)
    }
    
    var body: some View {
        LabeledValueView(label: label, value: glucoseString)
    }
}
