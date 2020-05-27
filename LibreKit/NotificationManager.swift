//
//  NotificationManager.swift
//  LibreKit
//
//  Created by Julian Groen on 18/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit
import UserNotifications
import AudioToolbox

struct NotificationManager {

    enum Identifier: String {
        case lowBattery       = "com.librekit.notifications.lowBattery"
        case glucoseAlarm     = "com.librekit.notifications.glucoseAlarm"
        case sensorExpire     = "com.librekit.notifications.sensorExpire"
        case newSensor        = "com.librekit.notifications.newSensor"
        case noSensorDetected = "com.librekit.notifications.noSensorDetected"
    }
    
    private static func add(identifier: Identifier, content: UNMutableNotificationContent) {
        let center = UNUserNotificationCenter.current()
        let request = UNNotificationRequest(identifier: identifier.rawValue, content: content, trigger: nil)

        center.removeDeliveredNotifications(withIdentifiers: [identifier.rawValue])
        center.removePendingNotificationRequests(withIdentifiers: [identifier.rawValue])
        center.add(request)
    }
    
    private static func ensureCanSendNotification(_ completion: @escaping (_ canSend: Bool) -> Void ) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if #available (iOSApplicationExtension 12.0, *) {
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                    completion(false)
                    return
                }
            } else {
                guard settings.authorizationStatus == .authorized  else {
                    completion(false)
                    return
                }
            }
            completion(true)
        }
    }
    
    private static var lastBatteryLevel: Int?

    public static func sendLowBatteryNotificationIfNeeded(_ transmitter: Transmitter?) {
        guard UserDefaults.standard.lowBatteryNotification, let transmitter = transmitter else {
            return
        }
        
        guard let battery = transmitter.battery else {
            return
        }
        
        if battery < lastBatteryLevel ?? 100 && battery <= 20 {
            ensureCanSendNotification { ensured in
                guard ensured else {
                    return
                }
                
                let notification = UNMutableNotificationContent()
                notification.title = LocalizedString("Transmitter Battery Low", comment: "The notification title for a low transmitter battery")
                notification.body = String(format: LocalizedString("%1$@ left", comment: "Low battery alert format string. (1: percentage remaining)"), "\(battery)%")
                notification.sound = .default
                
                add(identifier: .lowBattery, content: notification)
            }
        }
        
        lastBatteryLevel = battery
    }
    
    public static func sendGlucoseNotificationIfNeeded(current: Glucose?, last: Glucose?) {
        guard let currentGlucose = current, let lastGlucose = last else {
            return
        }
        
        let result = UserDefaults.standard.glucoseAlarm?.validateGlucose(currentGlucose.glucose) ?? .none
        
        if let glucoseUnit = UserDefaults.standard.glucoseUnit, result.isAlarming() {
            let formatter = QuantityFormatter()
            formatter.setPreferredNumberFormatter(for: glucoseUnit)
            
            guard let formatted = formatter.string(from: currentGlucose.quantity, for: glucoseUnit) else {
                return
            }
            
            let notification = UNMutableNotificationContent()
            
            switch result {
            case .low:
                notification.title = LocalizedString("Low Glucose", comment: "The notification title for a low glucose")
            case .high:
                notification.title = LocalizedString("High Glucose", comment: "The notification title for a high glucose")
            default:
                return
            }
            
            let difference = currentGlucose.glucose - lastGlucose.glucose
            let sign = difference < 0 ? "-" : "+"
            let glucose = Glucose(glucose: abs(difference), trend: .flat, minutes: 0, state: .unknown, timestamp: 0)
            
            guard let formattedDifference = formatter.string(from: glucose.quantity, for: glucoseUnit) else {
                return
            }
            
            notification.body = "\(formatted) \(currentGlucose.trend.symbol) \(sign)\(formattedDifference)"
            notification.sound = .default
            
            add(identifier: .glucoseAlarm, content: notification)
        }
    }
    
    public static func sendSensorChangeNotificationIfNeeded() {
        guard UserDefaults.standard.newSensorNotification else {
            return
        }
        
        ensureCanSendNotification { ensured in
            guard ensured else {
                return
            }
            
            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("New Sensor Detected", comment: "The notification title for a new detected sensor")
            notification.body = LocalizedString("Please wait up to 30 minutes before glucose readings are available", comment: "The notification body for a new detected sensor")
            notification.sound = .default

            add(identifier: .newSensor, content: notification)
        }
    }
    
    public static func sendSensorNotDetectedNotificationIfNeeded() {
        guard UserDefaults.standard.noSensorNotification else {
            return
        }
        
        ensureCanSendNotification { ensured in
            guard ensured else {
                return
            }
            
            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("No Sensor Detected", comment: "The notification title for a not detected sensor")
            notification.body = LocalizedString("Please check if your transmitter is tightly secured over your sensor", comment: "The notification body for a not detected sensor")
            notification.sound = .default
            
            add(identifier: .noSensorDetected, content: notification)
        }
    }
    
    private static var lastSensorAge: Int?

    public static func sendSensorExpireAlertIfNeeded(_ data: SensorData) {
        guard UserDefaults.standard.sensorExpireNotification else {
            return
        }
        
        var body: String?
        
        switch data.minutes {
        case let x where x >= 15840 && !(lastSensorAge ?? 0 >= 15840): // three days
            body = String(format: LocalizedString("Replace sensor in %1$@ days", comment: "Sensor expiring alert format string. (1: days left)"), 3)
        case let x where x >= 17280 && !(lastSensorAge ?? 0 >= 17280): // two days
            body = String(format: LocalizedString("Replace sensor in %1$@ days", comment: "Sensor expiring alert format string. (1: days left)"), 2)
        case let x where x >= 18720 && !(lastSensorAge ?? 0 >= 18720): // one day
            body = String(format: LocalizedString("Replace sensor in %1$@ day", comment: "Sensor expiring alert format string. (1: day left)"), 1)
        case let x where x >= 19440 && !(lastSensorAge ?? 0 >= 19440): // twelve hours
            body = String(format: LocalizedString("Replace sensor in %1$@ hours", comment: "Sensor expiring alert format string. (1: hours left)"), 12)
        case let x where x >= 20100 && !(lastSensorAge ?? 0 >= 20100): // one hour
            body = String(format: LocalizedString("Replace sensor in %1$@ hour", comment: "Sensor expiring alert format string. (1: hour left)"), 1)
        default:
            body = nil
        }
        
        lastSensorAge = data.minutes
        
        guard let notificationBody = body else {
            return
        }
        
        let notification = UNMutableNotificationContent()
        notification.title = LocalizedString("Sensor Ending Soon", comment: "The notification title for an ending sensor")
        notification.body = notificationBody
        notification.sound = .default
        
        add(identifier: .sensorExpire, content: notification)
    }

}
