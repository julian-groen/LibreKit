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
        case sensorExpire = "com.librekit.notifications.sensorExpire"
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
    
    public static func sendSensorExpireNotificationIfNeeded(_ data: SensorData) {
        switch data.wearTimeMinutes {
        case let x where x >= 15840 && !(UserDefaults.standard.lastSensorAge ?? 0 >= 15840): // three days
            sendSensorExpiringNotification(body: String(format: LocalizedString("Replace sensor in %1$@ days"), "3"))
        case let x where x >= 17280 && !(UserDefaults.standard.lastSensorAge ?? 0 >= 17280): // two days
            sendSensorExpiringNotification(body: String(format: LocalizedString("Replace sensor in %1$@ days"), "2"))
        case let x where x >= 18720 && !(UserDefaults.standard.lastSensorAge ?? 0 >= 18720): // one day
            sendSensorExpiringNotification(body: String(format: LocalizedString("Replace sensor in %1$@ day"), "1"))
        case let x where x >= 19440 && !(UserDefaults.standard.lastSensorAge ?? 0 >= 19440): // twelve hours
            sendSensorExpiringNotification(body: String(format: LocalizedString("Replace sensor in %1$@ hours"), "12"))
        case let x where x >= 20100 && !(UserDefaults.standard.lastSensorAge ?? 0 >= 20100): // one hour
            sendSensorExpiringNotification(body: String(format: LocalizedString("Replace sensor in %1$@ hour"), "1"))
        case let x where x >= 20160: // expired
            sendSensorExpiredNotification()
        default:
            break
        }
        
        UserDefaults.standard.lastSensorAge = data.wearTimeMinutes
    }
    
    private static func sendSensorExpiringNotification(body: String) {
        ensureCanSendNotification { ensured in
            guard ensured else {
                return
            }
            
            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Sensor ending soon")
            notification.body = body
            notification.sound = .default
            
            add(identifier: .sensorExpire, content: notification)
        }
    }
    
    private static func sendSensorExpiredNotification() {
        ensureCanSendNotification { ensured in
            guard ensured else {
                return
            }
            
            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Sensor expired")
            notification.body = LocalizedString("Please replace your old sensor as soon as possible")
            notification.sound = .default
            
            add(identifier: .sensorExpire, content: notification)
        }
    }

}
