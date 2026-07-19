import SwiftUI

struct StepsView: View {
    @EnvironmentObject private var healthKit: HealthKitManager
    @State private var stepInput = ""
    @State private var selectedDate = Date()
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @FocusState private var isStepFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 0) {
                        ForEach(
                            Array([100, 1000, 3000, 5000, 10000].enumerated()),
                            id: \.element
                        ) { index, preset in
                            let isSelected = stepInput == "\(preset)"

                            Button {
                                stepInput = "\(preset)"
                                isStepFieldFocused = false
                            } label: {
                                Text(preset, format: .number.grouping(.automatic))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? Color.accentColor : Color.clear)
                            }
                            .buttonStyle(.plain)

                            if index < 4 {
                                Divider()
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.45), lineWidth: 1)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Quick Select")
                }

                Section {
                    LabeledContent("Steps") {
                        TextField("0", text: $stepInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isStepFieldFocused)
                    }

                    DatePicker(
                        "Time",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("Details")
                } footer: {
                    Text("Enter steps, then tap Add Steps to write them to the Health app.")
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
                            Text(healthKit.isBusy ? "Adding…" : "Add Steps")
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
            }
            .navigationTitle("Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppBrandToolbarLabel()
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isStepFieldFocused = false
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .task {
                await prepareHealthKit()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func prepareHealthKit() async {
        guard healthKit.isHealthDataAvailable else {
            presentAlert(
                title: String(localized: "Unavailable"),
                message: HealthKitError.notAvailable.localizedDescription
            )
            return
        }

        do {
            try await healthKit.requestAuthorization()
        } catch {
            presentAlert(
                title: String(localized: "Authorization failed"),
                message: error.localizedDescription
            )
        }
    }

    private func syncSteps() async {
        let trimmed = stepInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let steps = Int(trimmed), steps > 0 else {
            presentAlert(
                title: String(localized: "Invalid input"),
                message: HealthKitError.invalidStepCount.localizedDescription
            )
            return
        }

        do {
            try await healthKit.addSteps(steps, date: selectedDate)
            stepInput = ""
            isStepFieldFocused = false
        } catch {
            presentAlert(
                title: String(localized: "Sync failed"),
                message: error.localizedDescription
            )
        }
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    StepsView()
        .environmentObject(HealthKitManager())
}
