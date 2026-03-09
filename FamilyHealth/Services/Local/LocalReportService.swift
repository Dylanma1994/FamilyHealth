import Foundation
import SwiftData

@MainActor
final class LocalReportService: ReportService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createReport(_ report: HealthReport) async throws {
        context.insert(report)
        try context.save()
    }

    func fetchReports(userId: UUID) async throws -> [HealthReport] {
        var descriptor = FetchDescriptor<HealthReport>(
            sortBy: [SortDescriptor(\.reportDate, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        return try context.fetch(descriptor).filter { $0.userId == userId }
    }

    func fetchReport(id: UUID) async throws -> HealthReport? {
        let descriptor = FetchDescriptor<HealthReport>()
        return try context.fetch(descriptor).first { $0.id == id }
    }

    func updateReport(_ report: HealthReport) async throws {
        report.updatedAt = Date()
        try context.save()
    }

    func deleteReport(id: UUID) async throws {
        let descriptor = FetchDescriptor<HealthReport>()
        if let report = try context.fetch(descriptor).first(where: { $0.id == id }) {
            context.delete(report)
            try context.save()
        }
    }

    func searchReports(query: String, userId: UUID?) async throws -> [HealthReport] {
        var descriptor = FetchDescriptor<HealthReport>(
            sortBy: [SortDescriptor(\.reportDate, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        let all = try context.fetch(descriptor)
        return all.filter { report in
            let matchesUser = userId == nil || report.userId == userId
            let matchesQuery = query.isEmpty ||
                report.title.localizedStandardContains(query) ||
                (report.hospitalName?.localizedStandardContains(query) ?? false)
            return matchesUser && matchesQuery
        }
    }
}
