import Foundation
import SwiftData

@MainActor
final class LocalCaseService: CaseService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createCase(_ medicalCase: MedicalCase) async throws {
        context.insert(medicalCase)
        try context.save()
    }

    func fetchCases(userId: UUID) async throws -> [MedicalCase] {
        var descriptor = FetchDescriptor<MedicalCase>(
            sortBy: [SortDescriptor(\.visitDate, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        return try context.fetch(descriptor).filter { $0.userId == userId }
    }

    func fetchCase(id: UUID) async throws -> MedicalCase? {
        let descriptor = FetchDescriptor<MedicalCase>()
        return try context.fetch(descriptor).first { $0.id == id }
    }

    func updateCase(_ medicalCase: MedicalCase) async throws {
        medicalCase.updatedAt = Date()
        try context.save()
    }

    func deleteCase(id: UUID) async throws {
        let descriptor = FetchDescriptor<MedicalCase>()
        if let medicalCase = try context.fetch(descriptor).first(where: { $0.id == id }) {
            context.delete(medicalCase)
            try context.save()
        }
    }

    func searchCases(query: String, userId: UUID?) async throws -> [MedicalCase] {
        var descriptor = FetchDescriptor<MedicalCase>(
            sortBy: [SortDescriptor(\.visitDate, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        let all = try context.fetch(descriptor)
        return all.filter { medCase in
            let matchesUser = userId == nil || medCase.userId == userId
            let matchesQuery = query.isEmpty ||
                medCase.title.localizedStandardContains(query) ||
                (medCase.diagnosis?.localizedStandardContains(query) ?? false)
            return matchesUser && matchesQuery
        }
    }
}
