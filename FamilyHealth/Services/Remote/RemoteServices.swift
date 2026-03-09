import Foundation

/// Remote mode implementations that forward operations to the Go server via REST API.

// MARK: - Remote Auth Service

final class RemoteAuthService: AuthService {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func createLocalUser(phone: String, name: String, gender: User.Gender) async throws -> User {
        struct LoginReq: Encodable { let phone: String; let name: String; let gender: String }
        struct LoginRes: Decodable { let token: String; let user: RemoteUser; let is_new: Bool }
        struct RemoteUser: Decodable {
            let id: UUID; let phone: String; let name: String
            let gender: String?; let avatar_url: String?
        }

        let res: LoginRes = try await api.post("/api/v1/auth/login",
            body: LoginReq(phone: phone, name: name, gender: gender.rawValue))
        await api.setToken(res.token)

        let user = User(phone: res.user.phone, name: res.user.name,
                        gender: User.Gender(rawValue: res.user.gender ?? "male") ?? .male)
        user.id = res.user.id
        return user
    }

    func getCurrentUser() async throws -> User? {
        // Server returns current user from JWT
        return nil // Handled via cached local state
    }

    func updateUser(_ user: User) async throws {
        struct UserUpdateDTO: Encodable {
            let name: String; let gender: String
            let height: Double?; let weight: Double?
        }
        let dto = UserUpdateDTO(name: user.name, gender: user.gender.rawValue,
                                height: user.height, weight: user.weight)
        let _: EmptyResponse = try await api.put("/api/v1/users/me", body: dto)
    }

    func deleteUser(id: UUID) async throws {
        try await api.delete("/api/v1/users/\(id)")
    }

    func findUser(byPhone phone: String) async throws -> User? {
        return nil // TODO: implement remote user search
    }
}

// MARK: - Remote Report Service

final class RemoteReportService: ReportService {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func createReport(_ report: HealthReport) async throws {
        let dto = report.toDTO()
        let _: HealthReportDTO = try await api.post("/api/v1/reports", body: dto)
    }

    func fetchReports(userId: UUID) async throws -> [HealthReport] {
        // TODO: parse DTO → Model when remote mode is fully implemented
        return []
    }

    func fetchReport(id: UUID) async throws -> HealthReport? {
        // TODO: parse DTO → Model when remote mode is fully implemented
        return nil
    }

    func updateReport(_ report: HealthReport) async throws {
        let dto = report.toDTO()
        let _: HealthReportDTO = try await api.put("/api/v1/reports/\(report.id)", body: dto)
    }

    func deleteReport(id: UUID) async throws {
        try await api.delete("/api/v1/reports/\(id)")
    }

    func searchReports(query: String, userId: UUID?) async throws -> [HealthReport] {
        return [] // TODO: implement search endpoint
    }
}

// MARK: - Remote Case Service

final class RemoteCaseService: CaseService {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func createCase(_ medicalCase: MedicalCase) async throws {
        let dto = medicalCase.toDTO()
        let _: MedicalCaseDTO = try await api.post("/api/v1/cases", body: dto)
    }

    func fetchCases(userId: UUID) async throws -> [MedicalCase] {
        // TODO: parse DTO → Model when remote mode is fully implemented
        return []
    }

    func fetchCase(id: UUID) async throws -> MedicalCase? {
        // TODO: parse DTO → Model when remote mode is fully implemented
        return nil
    }

    func updateCase(_ medicalCase: MedicalCase) async throws {
        let dto = medicalCase.toDTO()
        let _: MedicalCaseDTO = try await api.put("/api/v1/cases/\(medicalCase.id)", body: dto)
    }

    func deleteCase(id: UUID) async throws {
        try await api.delete("/api/v1/cases/\(id)")
    }

    func searchCases(query: String, userId: UUID?) async throws -> [MedicalCase] {
        return [] // TODO: implement search endpoint
    }
}

// MARK: - Remote Family Service

final class RemoteFamilyService: FamilyService {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func createGroup(name: String, creatorId: UUID) async throws -> FamilyGroup {
        struct CreateReq: Encodable { let name: String }
        struct GroupRes: Decodable {
            let id: UUID; let name: String; let creator_id: UUID; let created_at: String
        }
        let res: GroupRes = try await api.post("/api/v1/families", body: CreateReq(name: name))
        return FamilyGroup(name: res.name, creatorId: res.creator_id)
    }

    func fetchGroups(userId: UUID) async throws -> [FamilyGroup] {
        return [] // TODO: parse remote groups
    }

    func fetchGroup(id: UUID) async throws -> FamilyGroup? {
        return nil // TODO: implement
    }

    func deleteGroup(id: UUID) async throws {
        try await api.delete("/api/v1/families/\(id)")
    }

    func addMember(groupId: UUID, userId: UUID, role: FamilyMember.Role, invitedBy: UUID) async throws {
        // Via invite code flow on server
    }

    func removeMember(groupId: UUID, userId: UUID) async throws {
        // TODO: add endpoint
    }

    func getMembers(groupId: UUID) async throws -> [FamilyMember] {
        return [] // TODO: implement
    }

    func getUserGroupCount(userId: UUID) async throws -> Int {
        return 0 // TODO: implement
    }

    func isAdmin(userId: UUID, groupId: UUID) async throws -> Bool {
        return false // TODO: implement
    }

    func generateInviteCode(groupId: UUID) async throws -> String {
        struct InvRes: Decodable { let invite_code: String; let qr_data: String }
        let res: InvRes = try await api.post("/api/v1/families/\(groupId)/qrcode")
        return res.qr_data
    }
}
