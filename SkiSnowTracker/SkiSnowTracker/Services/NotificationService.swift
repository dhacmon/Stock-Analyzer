import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private override init() {
        super.init()
        checkAuthorizationStatus()
    }

    // MARK: - Permission Handling

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)

                if granted {
                    self.registerForRemoteNotifications()
                }
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Snow Dump Notifications

    func scheduleSnowDumpNotification(resortName: String, newSnowAmount: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "POWDER ALERT!"
        content.subtitle = resortName
        content.body = "\(newSnowAmount)cm of fresh snow just dropped! Time to shred!"
        content.sound = .default
        content.badge = 1

        // Add category for actions
        content.categoryIdentifier = "SNOW_DUMP"

        // Trigger immediately for demo, in production this would be triggered by backend
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "snow_dump_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snow dump notification: \(error)")
            }
        }
    }

    func scheduleDailySnowUpdate(resortName: String, hour: Int = 7, minute: Int = 0) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Snow Report"
        content.subtitle = resortName
        content.body = "Check out today's snow conditions!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_UPDATE"

        // Schedule for every day at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_snow_update",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily update: \(error)")
            }
        }
    }

    func scheduleTripCountdownNotification(resortName: String, tripDate: Date) {
        guard isAuthorized else { return }

        let daysUntilTrip = Calendar.current.dateComponents([.day], from: Date(), to: tripDate).day ?? 0

        // Schedule notifications at key milestones
        let milestones = [7, 3, 1]

        for milestone in milestones where daysUntilTrip > milestone {
            let notificationDate = Calendar.current.date(byAdding: .day, value: -milestone, to: tripDate)!

            let content = UNMutableNotificationContent()
            content.title = milestone == 1 ? "TOMORROW!" : "\(milestone) Days to Go!"
            content.subtitle = resortName
            content.body = milestone == 1
                ? "Your ski trip is tomorrow! Time to pack!"
                : "Only \(milestone) days until your ski trip to \(resortName)!"
            content.sound = .default
            content.categoryIdentifier = "TRIP_COUNTDOWN"

            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: "trip_countdown_\(milestone)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling countdown notification: \(error)")
                }
            }
        }
    }

    func scheduleBlizzardAlert(resortName: String, expectedSnowfall: Int, date: Date) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "BLIZZARD INCOMING!"
        content.subtitle = resortName
        content.body = "Major storm expected! \(expectedSnowfall)cm of fresh powder on the way!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("blizzard_alert.wav"))
        content.badge = 1
        content.categoryIdentifier = "BLIZZARD_ALERT"

        // Schedule for the day before the blizzard
        let alertDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: alertDate)
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "blizzard_alert_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling blizzard alert: \(error)")
            }
        }
    }

    // MARK: - Notification Management

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func setupNotificationCategories() {
        // Snow dump action
        let viewAction = UNNotificationAction(
            identifier: "VIEW_CONDITIONS",
            title: "View Conditions",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )

        let snowDumpCategory = UNNotificationCategory(
            identifier: "SNOW_DUMP",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let blizzardCategory = UNNotificationCategory(
            identifier: "BLIZZARD_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_UPDATE",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        let countdownCategory = UNNotificationCategory(
            identifier: "TRIP_COUNTDOWN",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            snowDumpCategory,
            blizzardCategory,
            dailyCategory,
            countdownCategory
        ])
    }
}

// MARK: - Notification Delegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        switch actionIdentifier {
        case "VIEW_CONDITIONS":
            // Handle view action - post notification to navigate to conditions
            NotificationCenter.default.post(name: .showConditions, object: nil)
        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showConditions = Notification.Name("showConditions")
    static let snowDumpReceived = Notification.Name("snowDumpReceived")
}
