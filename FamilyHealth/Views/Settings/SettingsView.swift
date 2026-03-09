import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Query private var allUsers: [User]

    private var currentUser: User? {
        guard let id = appState.currentUserId, let uuid = UUID(uuidString: id) else { return nil }
        return allUsers.first(where: { $0.id == uuid })
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: FHSpacing.lg) {
                        Circle()
                            .fill(FHGradients.profileAvatar)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            )
                            .fhShadow(.light)

                        VStack(alignment: .leading, spacing: FHSpacing.xs) {
                            Text(currentUser?.name ?? "用户")
                                .font(.title3.bold())
                            HStack(spacing: 4) {
                                if let user = currentUser {
                                    Text(user.gender == .male ? "♂" : "♀")
                                    Text(user.phone)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(appState.mode.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, FHSpacing.sm)
                                    .padding(.vertical, 2)
                                    .background(FHColors.success.opacity(0.1))
                                    .foregroundStyle(FHColors.success)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, FHSpacing.xs)
                }

                // Account
                Section("账户") {
                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        Label("个人资料", systemImage: "person.circle")
                    }

                    NavigationLink {
                        ModeSettingsView()
                    } label: {
                        Label("运行模式", systemImage: "globe")
                    }
                }

                // AI Config
                Section("AI 配置") {
                    NavigationLink {
                        AIModelSettingsView()
                    } label: {
                        HStack {
                            Label("AI 模型设置", systemImage: "cpu")
                            Spacer()
                        }
                    }
                }

                // General
                Section("通用") {
                    NavigationLink {
                        Text("语言设置") // TODO
                    } label: {
                        HStack {
                            Label("语言 Language", systemImage: "globe")
                            Spacer()
                            Text("简体中文")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        Text("数据管理") // TODO
                    } label: {
                        Label("数据管理", systemImage: "externaldrive")
                    }
                }

                // About
                Section("关于") {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("v1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink { Text("隐私政策") } label: {
                        Label("隐私政策", systemImage: "hand.raised")
                    }

                    NavigationLink { Text("使用帮助") } label: {
                        Label("使用帮助", systemImage: "questionmark.circle")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - Mode Settings
struct ModeSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var serverURL = ""
    @State private var syncLocalData = false

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: appState.mode == .local ? "iphone" : "cloud")
                        .font(.title2)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text("当前：\(appState.mode.displayName)")
                            .font(.headline)
                        Text(appState.mode == .local ?
                             "所有数据存储在设备本地，无需联网" :
                             "数据同步至云端服务器")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if appState.mode == .local {
                Section("切换到联网模式") {
                    TextField("服务端地址", text: $serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)

                    Button("测试连接") {
                        // TODO: test connection
                    }

                    Toggle("上传本地数据到云端", isOn: $syncLocalData)

                    Text("切换后，新数据将直接存储到云端")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Section {
                    Button("确认切换") {
                        appState.serverURL = serverURL
                        appState.mode = .remote
                    }
                    .disabled(serverURL.isEmpty)
                }
            } else {
                Section {
                    Button("切换到本地模式") {
                        appState.mode = .local
                    }
                }
            }
        }
        .navigationTitle("运行模式")
        .onAppear { serverURL = appState.serverURL }
    }
}

// MARK: - AI Model Settings
struct AIModelSettingsView: View {
    @Query private var configs: [AIModelConfig]
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false

    var body: some View {
        List {
            if configs.isEmpty {
                Section {
                    Text("尚未添加任何 AI 模型")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(configs) { config in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(config.name)
                                .font(.headline)
                            if config.isDefault {
                                Text("默认")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(FHColors.primary)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(config.provider.displayName + " · " + config.modelName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(config.apiEndpoint)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .contextMenu {
                    if !config.isDefault {
                        Button {
                            setAsDefault(config)
                        } label: {
                            Label("设为默认", systemImage: "checkmark.circle")
                        }
                    }
                    Button(role: .destructive) {
                        deleteConfig(config)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteConfig(config)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    if !config.isDefault {
                        Button {
                            setAsDefault(config)
                        } label: {
                            Label("默认", systemImage: "checkmark.circle")
                        }
                        .tint(FHColors.primary)
                    }
                }
            }

            Button {
                showAddSheet = true
            } label: {
                Label("添加新模型", systemImage: "plus")
            }
        }
        .navigationTitle("AI 模型设置")
        .sheet(isPresented: $showAddSheet) {
            AddAIModelView()
        }
    }

    private func setAsDefault(_ config: AIModelConfig) {
        for c in configs { c.isDefault = false }
        config.isDefault = true
        try? context.save()
    }

    private func deleteConfig(_ config: AIModelConfig) {
        try? KeychainManager.deleteAPIKey(for: config.id)
        let wasDefault = config.isDefault
        context.delete(config)
        try? context.save()
        if wasDefault, let first = configs.first {
            first.isDefault = true
            try? context.save()
        }
    }
}

// MARK: - Add AI Model
struct AddAIModelView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existingConfigs: [AIModelConfig]

    @State private var name = ""
    @State private var provider: AIModelConfig.Provider = .openai
    @State private var apiEndpoint = ""
    @State private var apiKey = ""
    @State private var modelName = ""
    @State private var isDefault = false
    @State private var testResult: String?
    @State private var testPassed = false
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)

                    Picker("提供商", selection: $provider) {
                        ForEach(AIModelConfig.Provider.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }

                Section("API 配置") {
                    TextField("API 地址（如 https://api.openai.com/v1）", text: $apiEndpoint)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .onChange(of: apiEndpoint) { _, _ in testPassed = false }

                    SecureField("API Key", text: $apiKey)
                        .onChange(of: apiKey) { _, _ in testPassed = false }

                    TextField("模型名称（如 gpt-4o）", text: $modelName)
                        .textInputAutocapitalization(.never)
                        .onChange(of: modelName) { _, _ in testPassed = false }
                }

                Section {
                    Button {
                        runTest()
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .controlSize(.small)
                                Text("测试中...")
                            } else {
                                Label("测试连接", systemImage: testPassed ? "checkmark.circle.fill" : "bolt.horizontal")
                            }
                        }
                    }
                    .disabled(apiEndpoint.isEmpty || apiKey.isEmpty || modelName.isEmpty || isTesting)

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(testPassed ? FHColors.success : FHColors.danger)
                    }
                } footer: {
                    Text("必须通过连接测试后才能保存模型")
                        .font(.caption2)
                }

                Section {
                    Toggle("设为默认模型", isOn: $isDefault)
                }
            }
            .navigationTitle("添加模型")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!testPassed || name.isEmpty)
                }
            }
        }
    }

    private func runTest() {
        isTesting = true
        testResult = nil
        testPassed = false

        Task {
            do {
                let client = OpenAIClient()
                let success = try await client.testConnection(
                    endpoint: apiEndpoint, apiKey: apiKey, model: modelName)
                testResult = success ? "✅ 连接成功，可以保存" : "❌ 连接失败"
                testPassed = success
            } catch {
                testResult = "❌ \(error.localizedDescription)"
                testPassed = false
            }
            isTesting = false
        }
    }

    private func save() {
        let shouldBeDefault = isDefault || existingConfigs.isEmpty
        if shouldBeDefault {
            for c in existingConfigs { c.isDefault = false }
        }

        let config = AIModelConfig(
            name: name,
            provider: provider,
            apiEndpoint: apiEndpoint,
            modelName: modelName,
            isDefault: shouldBeDefault
        )
        context.insert(config)
        try? KeychainManager.saveAPIKey(apiKey, for: config.id)
        try? context.save()

        dismiss()
    }
}

// MARK: - Profile Edit

struct ProfileEditView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allUsers: [User]
    @State private var name = ""
    @State private var gender: User.Gender = .male
    @State private var birthDate: Date = Date()
    @State private var hasBirthDate = false
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var currentUser: User? {
        guard let id = appState.currentUserId, let uuid = UUID(uuidString: id) else { return nil }
        return allUsers.first(where: { $0.id == uuid })
    }

    private var bmi: String? {
        guard let h = Double(heightCm), let w = Double(weightKg), h > 0 else { return nil }
        let bmiVal = w / ((h / 100) * (h / 100))
        return String(format: "%.1f", bmiVal)
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名", text: $name)
                Picker("性别", selection: $gender) {
                    ForEach(User.Gender.allCases, id: \.self) { g in
                        Text(g.displayName).tag(g)
                    }
                }
            }

            Section("出生日期") {
                Toggle("设置出生日期", isOn: $hasBirthDate)
                if hasBirthDate {
                    DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                }
            }

            Section {
                HStack {
                    Text("身高 (cm)")
                    Spacer()
                    TextField("170", text: $heightCm)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("体重 (kg)")
                    Spacer()
                    TextField("65", text: $weightKg)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                if let bmi = bmi {
                    HStack {
                        Text("BMI")
                        Spacer()
                        Text(bmi)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("身体数据")
            }
        }
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { saveProfile() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear { loadUser() }
        .swAlert(isPresented: $showAlert, type: .success, message: alertMessage)
    }

    private func loadUser() {
        guard let user = currentUser else { return }
        name = user.name
        gender = user.gender
        if let bd = user.birthDate {
            birthDate = bd
            hasBirthDate = true
        }
        if let h = user.height { heightCm = String(format: "%.0f", h) }
        if let w = user.weight { weightKg = String(format: "%.1f", w) }
    }

    private func saveProfile() {
        guard let user = currentUser else { return }
        user.name = name.trimmingCharacters(in: .whitespaces)
        user.gender = gender
        user.birthDate = hasBirthDate ? birthDate : nil
        user.height = Double(heightCm)
        user.weight = Double(weightKg)
        user.updatedAt = Date()
        try? context.save()

        alertMessage = "已保存"
        showAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
    }
}
