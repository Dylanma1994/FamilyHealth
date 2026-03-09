import SwiftUI
import SwiftData

/// ViewModel for HomeView — provides computed stats and greeting logic.
@Observable
final class HomeViewModel {
    var showUploadReport = false
    var showAddCase = false

    /// Greeting based on time of day.
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return String(localized: "早上好")
        case 12..<18: return String(localized: "下午好")
        default: return String(localized: "晚上好")
        }
    }

    /// Count of family members the user belongs to.
    func memberCount(userId: String?, familyMembers: [FamilyMember]) -> String {
        guard let userId, let uuid = UUID(uuidString: userId) else { return "—" }
        let groups = familyMembers.filter { $0.userId == uuid }.compactMap(\.group)
        let total = Set(groups.flatMap(\.members).map(\.userId)).count
        return total > 0 ? "\(total) 人" : "—"
    }

    /// Formatted date of the most recent health report.
    func lastCheckupDate(reports: [HealthReport]) -> String {
        guard let latest = reports.first?.reportDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: latest)
    }
}
