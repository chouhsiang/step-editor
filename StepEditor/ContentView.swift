import SwiftUI

struct ContentView: View {
    @StateObject private var healthKit = HealthKitManager()
    @State private var stepInput = ""
    @State private var selectedDate = Date()
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("要新增的步數", text: $stepInput)
                        .keyboardType(.numberPad)

                    DatePicker(
                        "紀錄時間",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("步數")
                } footer: {
                    Text("輸入後按下「同步到健康」，步數會寫入 iPhone「健康」App。")
                }

                Section {
                    Button {
                        Task { await syncSteps() }
                    } label: {
                        HStack {
                            Spacer()
                            if healthKit.isBusy {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(healthKit.isBusy ? "同步中…" : "同步到健康")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(healthKit.isBusy || stepInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if let message = healthKit.statusMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("若要刪除步數，請到「健康」App 的「步行」→「顯示所有資料」，找到本 App 寫入的紀錄後刪除。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("如何刪除步數")
                }

                Section {
                    Link(destination: URL(string: "https://github.com/chouhsiang/step-editor")!) {
                        Label("GitHub 開源專案", systemImage: "link")
                    }
                    Text("本專案為開源軟體，原始碼與說明請見 GitHub。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("關於")
                }
            }
            .navigationTitle("步數編輯器")
            .task {
                await prepareHealthKit()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func prepareHealthKit() async {
        guard healthKit.isHealthDataAvailable else {
            presentAlert(title: "無法使用", message: HealthKitError.notAvailable.localizedDescription)
            return
        }

        do {
            try await healthKit.requestAuthorization()
        } catch {
            presentAlert(title: "授權失敗", message: error.localizedDescription)
        }
    }

    private func syncSteps() async {
        let trimmed = stepInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let steps = Int(trimmed), steps > 0 else {
            presentAlert(title: "輸入有誤", message: HealthKitError.invalidStepCount.localizedDescription)
            return
        }

        do {
            try await healthKit.addSteps(steps, date: selectedDate)
            stepInput = ""
        } catch {
            presentAlert(title: "同步失敗", message: error.localizedDescription)
        }
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    ContentView()
}
