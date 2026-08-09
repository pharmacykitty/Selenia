import Foundation
import UserNotifications

/// Annual "it's their birthday" local notifications for saved charts.
///
/// One repeating calendar trigger per chart (the birth month + day, 9:00 in
/// whatever timezone the user is in when it fires). The pending-request id is
/// stored on the chart (`SavedChart.birthdayReminderID`), which doubles as the
/// on/off flag — no separate bookkeeping to drift out of sync. Transit
/// scheduling must never clear these ids (`TransitNotifications` filters on
/// the prefix).
enum BirthdayReminders {
    static let idPrefix = "birthday-"

    /// Request permission (first time) and schedule the annual reminder.
    /// Returns false when notification permission is denied.
    @MainActor
    @discardableResult
    static func enable(for chart: SavedChart) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = chart.name.isEmpty ? "Birthday today" : "\(chart.name)’s birthday"
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        df.timeZone = chart.timeZone
        content.body = "Born \(df.string(from: chart.birthDate)). Wish them a happy one."
        content.sound = .default

        // Matching month+day with repeats fires every year. A 29 Feb birthday
        // fires on leap years only (iOS matches the components literally) —
        // accepted; celebrating on the true date reads as a feature.
        var comps = DateComponents()
        comps.month = chart.month
        comps.day = chart.day
        comps.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let id = chart.birthdayReminderID ?? idPrefix + UUID().uuidString
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        chart.birthdayReminderID = id
        return true
    }

    /// Cancel the reminder (also called when a chart is deleted).
    @MainActor
    static func disable(for chart: SavedChart) {
        guard let id = chart.birthdayReminderID else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        chart.birthdayReminderID = nil
    }
}
