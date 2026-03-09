import Foundation
import SwiftData

@MainActor
final class LocalAuthService: AuthService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createLocalUser(phone: String, name: String, gender: User.Gender) async throws -> User {
        let user = User(phone: phone, name: name, gender: gender)
        context.insert(user)
        try context.save()
        return user
    }

    func getCurrentUser() async throws -> User? {
        guard let idStr = UserDefaults.standard.string(forKey: "current_user_id"),
              let id = UUID(uuidString: idStr) else { return nil }

        let descriptor = FetchDescriptor<User>()
        return try context.fetch(descriptor).first { $0.id == id }
    }

    func updateUser(_ user: User) async throws {
        user.updatedAt = Date()
        try context.save()
    }

    func deleteUser(id: UUID) async throws {
        let descriptor = FetchDescriptor<User>()
        if let user = try context.fetch(descriptor).first(where: { $0.id == id }) {
            context.delete(user)
            try context.save()
        }
    }

    func findUser(byPhone phone: String) async throws -> User? {
        let descriptor = FetchDescriptor<User>()
        return try context.fetch(descriptor).first { $0.phone == phone }
    }
}
