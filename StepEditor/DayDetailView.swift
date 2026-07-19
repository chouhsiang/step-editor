import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject private var healthKit: HealthKitManager
    let dayStart: Date

    @State private var records: [StepSampleRecord] = []
    @State private var isLoading = false
    @State private var isEditing = false
    @State private var errorMessage: String?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showDeleteAllConfirm = false

    private var deletableRecords: [StepSampleRecord] {
        records.filter(\.canDelete)
    }

    var body: some View {
        Group {
            if isLoading && records.isEmpty {
                ProgressView("Loading…")
            } else if let errorMessage, records.isEmpty {
                ContentUnavailableView(
                    "Unable to load records",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if records.isEmpty {
                ContentUnavailableView(
                    "No records",
                    systemImage: "list.bullet",
                    description: Text("No individual step records for this day.")
                )
            } else {
                List {
                    Section {
                        ForEach(records) { record in
                            if isEditing {
                                editableRow(record)
                            } else {
                                NavigationLink(value: record) {
                                    sampleRow(record)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if record.canDelete {
                                        Button(role: .destructive) {
                                            Task { await delete(record) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("steps")
                    } footer: {
                        Text("Only records written by Step Patch can be deleted.")
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await loadRecords()
                }
            }
        }
        .navigationTitle("All Recorded Data")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: StepSampleRecord.self) { record in
            SampleDetailView(record: record)
        }
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Delete All") {
                        showDeleteAllConfirm = true
                    }
                    .disabled(deletableRecords.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.accentColor)
                            .font(.title2)
                    }
                    .accessibilityLabel(Text("Done"))
                }
            } else if !records.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .task {
            await loadRecords()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Delete all Step Patch records for this day?",
            isPresented: $showDeleteAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                Task { await deleteAllDeletable() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func sampleRow(_ record: StepSampleRecord) -> some View {
        HStack(spacing: 12) {
            sourceIcon(for: record)
            Text(record.steps, format: .number.grouping(.automatic))
            Spacer()
            Text(record.startDate, format: sampleTimeFormat)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func editableRow(_ record: StepSampleRecord) -> some View {
        HStack(spacing: 12) {
            Button {
                Task { await delete(record) }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(record.canDelete ? .red : .secondary.opacity(0.35))
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!record.canDelete)

            sourceIcon(for: record)
            Text(record.steps, format: .number.grouping(.automatic))
            Spacer()
            Text(record.startDate, format: sampleTimeFormat)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func sourceIcon(for record: StepSampleRecord) -> some View {
        Group {
            if record.canDelete {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else if record.isAppleSource {
                Image(systemName: "iphone")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: "app.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private var sampleTimeFormat: Date.FormatStyle {
        .dateTime.month().day().hour().minute()
    }

    private func loadRecords() async {
        isLoading = true
        defer { isLoading = false }

        do {
            records = try await healthKit.fetchSamples(on: dayStart)
            errorMessage = nil
            if records.isEmpty {
                isEditing = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ record: StepSampleRecord) async {
        guard record.canDelete else {
            alertTitle = String(localized: "Delete failed")
            alertMessage = String(localized: "Only records written by this app can be deleted.")
            showAlert = true
            return
        }

        do {
            try await healthKit.deleteSample(record)
            records.removeAll { $0.id == record.id }
            if records.isEmpty {
                isEditing = false
            }
        } catch {
            alertTitle = String(localized: "Delete failed")
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func deleteAllDeletable() async {
        let targets = deletableRecords
        guard !targets.isEmpty else { return }

        do {
            try await healthKit.deleteSamples(targets)
            let ids = Set(targets.map(\.id))
            records.removeAll { ids.contains($0.id) }
            isEditing = false
        } catch {
            alertTitle = String(localized: "Delete failed")
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
