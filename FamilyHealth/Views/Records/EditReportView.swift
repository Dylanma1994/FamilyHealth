import SwiftUI

/// Edit an existing health report's metadata
struct EditReportView: View {
    let report: HealthReport
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var hospitalName: String
    @State private var reportDate: Date
    @State private var reportType: HealthReport.ReportType
    @State private var notes: String
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertType: SWAlertType = .success
    @State private var alertMessage = ""

    init(report: HealthReport) {
        self.report = report
        _title = State(initialValue: report.title)
        _hospitalName = State(initialValue: report.hospitalName ?? "")
        _reportDate = State(initialValue: report.reportDate)
        _reportType = State(initialValue: report.reportType)
        _notes = State(initialValue: report.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("报告标题") {
                    TextField("例：2025年度体检报告", text: $title)
                }

                Section("医院信息") {
                    TextField("医院名称", text: $hospitalName)
                    DatePicker("体检日期", selection: $reportDate, displayedComponents: .date)
                }

                Section("报告类型") {
                    Picker("类型", selection: $reportType) {
                        ForEach(HealthReport.ReportType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("备注（可选）") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                // Image preview (read-only)
                if !report.files.isEmpty {
                    Section("报告图片") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: FHSpacing.sm) {
                                ForEach(report.files) { file in
                                    if let data = FileManager.default.contents(atPath: file.localPath),
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: FHRadius.small))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("编辑报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("保存")
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .swAlert(isPresented: $showAlert, type: alertType, message: alertMessage)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        report.title = title
        report.hospitalName = hospitalName.isEmpty ? nil : hospitalName
        report.reportDate = reportDate
        report.reportType = reportType
        report.notes = notes.isEmpty ? nil : notes

        do {
            try await services.reportService.updateReport(report)
            alertType = .success
            alertMessage = "保存成功"
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
        } catch {
            alertType = .error
            alertMessage = "保存失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
