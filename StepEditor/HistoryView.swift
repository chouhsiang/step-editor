import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var healthKit: HealthKitManager
    @State private var summaries: [DailyStepSummary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && summaries.isEmpty {
                    ProgressView("Loading…")
                } else if let errorMessage, summaries.isEmpty {
                    ContentUnavailableView(
                        "Unable to load steps",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if summaries.isEmpty {
                    ContentUnavailableView(
                        "No step data",
                        systemImage: "figure.walk",
                        description: Text("Step totals from the Health app will appear here.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(summaries) { summary in
                                NavigationLink(value: summary) {
                                    HStack {
                                        Text(summary.steps, format: .number.grouping(.automatic))
                                            .font(.body.weight(.regular))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(summary.dayStart, format: healthDayFormat)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("steps")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadSummaries()
                    }
                }
            }
            .navigationTitle("All Recorded Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DailyStepSummary.self) { summary in
                DayDetailView(dayStart: summary.dayStart)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadSummaries() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .principal) {
                    AppBrandToolbarLabel()
                }
            }
            .task {
                await loadSummaries()
            }
        }
    }

    private var healthDayFormat: Date.FormatStyle {
        .dateTime.year().month().day()
    }

    private func loadSummaries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            summaries = try await healthKit.fetchDailySummaries()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(HealthKitManager())
}
