import Foundation

/// Remote mode implementations that forward operations to the Go server via REST API.

// MARK: - Paginated Response

struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let total: Int64
    let page: Int
}

// MARK: - Remote Auth Service

final class RemoteAuthService: AuthService {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func createLocalUser(phone: String, name: String, gender: User.Gender) async throws -> User {
        struct LoginReq: Encodable { let phone: String; let name: String; let code: String }
        struct LoginRes: Decodable {
            let token: String; let user: RemoteUser; let is_new: Bool
        }
        struct RemoteUser: Decodable {
            let id: UUID; let phone: String; let name: String
            let gender: String?; let avatar_url: String?
            let height: Double?; let weight: Double?
            let birth_date: Date?
        }

        let res: LoginRes = try await api.post("/api/v1/auth/login",
            body: LoginReq(phone: phone, name: name, code: "000000"))
        await api.setToken(res.token)

        let user = User(phone: res.user.phone, name: res.user.name,
                        gender: User.Gender(rawValue: res.user.gender ?? "male") ?? .male)
        user.id = res.user.id
        if let h = res.user.height { user.height = h }
        if let w = res.user.weight { user.weight = w }
        if let b = res.user.birth_date { user.birthDate = b }
        return user
    }

    func getCurrentUser() async throws -> User? {
        struct RemoteUser: Decodable {
            let id: UUID; let phone: String; let name: String
            let gender: String?; let height: Double?; let weight: Double?
        }
        let remote: RemoteUser = try await api.get("/api/v1/users/me")
        let user = User(phone: remote.phone, name: remote.name,
                        gender: User.Gender(rawValue: remote.gender ?? "male") ?? .male)
        user.id = remote.id
        if let h = remote.height { user.height = h }
        if let w = remote.weight { user.weight = w }
        return user
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
        return nil // Server-side user search not exposed
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
        let response: PaginatedResponse<HealthReportDTO> = try await api.get(
            "/api/v1/reports",
            query: ["user_id": userId.uuidString, "size": "100"]
        )
        return response.items.map { $0.toModel() }
    }

    func fetchReport(id: UUID) async throws -> HealthReport? {
        let dto: HealthReportDTO = try await api.get("/api/v1/reports/\(id)")
        return dto.toModel()
    }

    func updateReport(_ report: HealthReport) async throws {
        let dto = report.toDTO()
        let _: HealthReportDTO = try await api.put("/api/v1/reports/\(report.id)", body: dto)
    }

    func deleteReport(id: UUID) async throws {
        try await api.delete("/api/v1/reports/\(id)")
    }

    func searchReports(query: String, userId: UUID?) async throws -> [HealthReport] {
        // Server doesn't have search endpoint yet; fetch all and filter client-side
        guard let uid = userId else { return [] }
        let all = try await fetchReports(userId: uid)
        guard !query.isEmpty else { return all }
        return all.filter { $0.title.localizedStandardContains(query) }
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
        let response: PaginatedResponse<MedicalCaseDTO> = try await api.get(
            "/api/v1/cases",
            query: ["size": "100"]
        )
        return response.items.map { $0.toModel() }
    }

    func fetchCase(id: UUID) async throws -> MedicalCase? {
        let dto: MedicalCaseDTO = try await api.get("/api/v1/cases/\(id)")
        return dto.toModel()
    }

    func updateCase(_ medicalCase: MedicalCase) async throws {
        let dto = medicalCase.toDTO()
        let _: MedicalCaseDTO = try await api.put("/api/v1/cases/\(medicalCase.id)", body: dto)
    }

    func deleteCase(id: UUID) async throws {
        try await api.delete("/api/v1/cases/\(id)")
    }

    func searchCases(query: String, userId: UUID?) async throws -> [MedicalCase] {
        guard let uid = userId else { return [] }
        let all = try await fetchCases(userId: uid)
        guard !query.isEmpty else { return all }
        return all.filter { $0.title.localizedStandardContains(query) }
    }
}

// MARK: - Remote Family Service

final class RemoteFamilyService: FamilyService {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func createGroup(name: String, creatorId: UUID) async throws -> FamilyGroup {
        struct CreateReq: Encodable { let name: String }
        struct GroupRes: Decodable { let id: UUID; let role: String }
        let res: GroupRes = try await api.post("/api/v1/families", body: CreateReq(name: name))
        let group = FamilyGroup(name: name, creatorId: creatorId)
        group.id = res.id
        return group
    }

    func fetchGroups(userId: UUID) async throws -> [FamilyGroup] {
        struct RemoteGroup: Decodable {
            let id: UUID; let name: String; let creator_id: UUID; let created_at: Date
            let members: [RemoteMember]?
        }
        struct RemoteMember: Decodable {
            let id: UUID; let user_id: UUID; let role: String; let joined_at: Date
        }
        let groups: [RemoteGroup] = try await api.get("/api/v1/families")
        return groups.map { g in
            let group = FamilyGroup(name: g.name, creatorId: g.creator_id)
            group.id = g.id
            group.createdAt = g.created_at
            return group
        }
    }

    func fetchGroup(id: UUID) async throws -> FamilyGroup? {
        struct RemoteGroup: Decodable {
            let id: UUID; let name: String; let creator_id: UUID; let created_at: Date
        }
        let g: RemoteGroup = try await api.get("/api/v1/families/\(id)")
        let group = FamilyGroup(name: g.name, creatorId: g.creator_id)
        group.id = g.id
        group.createdAt = g.created_at
        return group
    }

    func deleteGroup(id: UUID) async throws {
        try await api.delete("/api/v1/families/\(id)")
    }

    func addMember(groupId: UUID, userId: UUID, role: FamilyMember.Role, invitedBy: UUID) async throws {
        // Via invite code flow on server
    }

    func removeMember(groupId: UUID, userId: UUID) async throws {
        // TODO: server endpoint needed
    }

    func getMembers(groupId: UUID) async throws -> [FamilyMember] {
        return [] // Included in group fetch
    }

    func getUserGroupCount(userId: UUID) async throws -> Int {
        let groups = try await fetchGroups(userId: userId)
        return groups.count
    }

    func isAdmin(userId: UUID, groupId: UUID) async throws -> Bool {
        guard let group = try await fetchGroup(id: groupId) else { return false }
        return group.creatorId == userId
    }

    func generateInviteCode(groupId: UUID) async throws -> String {
        struct InvRes: Decodable { let invite_code: String; let qr_data: String }
        let res: InvRes = try await api.post("/api/v1/families/\(groupId)/qrcode")
        return res.qr_data
    }
}

// MARK: - DTO → Model Conversions

extension HealthReportDTO {
    func toModel() -> HealthReport {
        let report = HealthReport(
            id: id,
            userId: userId,
            uploaderId: uploaderId,
            title: title,
            hospitalName: hospitalName,
            reportDate: reportDate,
            reportType: HealthReport.ReportType(rawValue: reportType) ?? .other,
            notes: notes
        )
        report.aiAnalysis = aiAnalysis
        report.createdAt = createdAt
        report.updatedAt = updatedAt
        return report
    }
}

extension MedicalCaseDTO {
    func toModel() -> MedicalCase {
        let mc = MedicalCase(
            id: id,
            userId: userId,
            uploaderId: uploaderId,
            title: title,
            hospitalName: hospitalName,
            doctorName: doctorName,
            visitDate: visitDate,
            diagnosis: diagnosis,
            symptoms: symptoms,
            notes: notes
        )
        mc.createdAt = createdAt
        mc.updatedAt = updatedAt
        if let meds = medications {
            mc.medications = meds.map { med in
                Medication(
                    id: med.id,
                    name: med.name,
                    dosage: med.dosage,
                    frequency: med.frequency,
                    startDate: med.startDate,
                    endDate: med.endDate
                )
            }
        }
        return mc
    }
}
