import SwiftUI
import SwiftData

/// ViewModel for RecordsView — manages tab and search filtering state.
@Observable
final class RecordsViewModel {
    var selectedTab = 0
    var searchText = ""
    var showUploadReport = false
    var showAddCase = false

    /// Filter reports by search text.
    func filteredReports(_ reports: [HealthReport]) -> [HealthReport] {
        if searchText.isEmpty { return reports }
        return reports.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.hospitalName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// Filter cases by search text.
    func filteredCases(_ cases: [MedicalCase]) -> [MedicalCase] {
        if searchText.isEmpty { return cases }
        return cases.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.diagnosis?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// Trigger the add action based on the current tab.
    func addAction() {
        if selectedTab == 0 {
            showUploadReport = true
        } else {
            showAddCase = true
        }
    }
}
