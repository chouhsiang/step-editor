import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case invalidStepCount
    case saveFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return String(localized: "Health data is not available on this device.")
        case .authorizationDenied:
            return String(localized: "Write access for steps is not allowed. Enable it in Settings → Health → Data Access & Devices.")
        case .invalidStepCount:
            return String(localized: "Enter a whole number of steps greater than 0.")
        case .saveFailed(let message):
            return String(localized: "Failed to save: \(message)")
        case .deleteFailed(let message):
            return String(localized: "Failed to delete: \(message)")
        }
    }
}

struct DailyStepSummary: Identifiable, Hashable {
    let id: Date
    let dayStart: Date
    let steps: Int
}

struct StepSampleRecord: Identifiable, Hashable {
    let id: UUID
    let steps: Int
    let startDate: Date
    let endDate: Date
    let sourceName: String
    let canDelete: Bool
    let isAppleSource: Bool
    let creationDate: Date?
    let deviceName: String?
    let deviceManufacturer: String?
    let deviceModel: String?
    let deviceHardwareVersion: String?
    let deviceSoftwareVersion: String?
    let sample: HKQuantitySample

    static func == (lhs: StepSampleRecord, rhs: StepSampleRecord) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
final class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    @Published var isAuthorized = false
    @Published var statusMessage: String?
    @Published var isBusy = false

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }

        try await store.requestAuthorization(toShare: [stepType], read: [stepType])
        refreshAuthorizationStatus()
    }

    func requireWriteAuthorization() throws {
        refreshAuthorizationStatus()
        if !isAuthorized {
            throw HealthKitError.authorizationDenied
        }
    }

    func refreshAuthorizationStatus() {
        let status = store.authorizationStatus(for: stepType)
        isAuthorized = (status == .sharingAuthorized)
    }

    func addSteps(_ steps: Int, date: Date = .now) async throws {
        guard steps > 0 else {
            throw HealthKitError.invalidStepCount
        }

        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }

        isBusy = true
        defer { isBusy = false }

        try await requestAuthorization()
        try requireWriteAuthorization()

        let quantity = HKQuantity(unit: .count(), doubleValue: Double(steps))
        let sample = HKQuantitySample(
            type: stepType,
            quantity: quantity,
            start: date,
            end: date
        )

        do {
            try await store.save(sample)
            statusMessage = String(localized: "Added \(steps) steps to the Health app")
        } catch {
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }

    func fetchDailySummaries(days: Int = 90) async throws -> [DailyStepSummary] {
        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }

        try await requestAuthorization()

        let calendar = Calendar.current
        let endDate = Date()
        let startOfToday = calendar.startOfDay(for: endDate)
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let interval = DateComponents(day: 1)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var summaries: [DailyStepSummary] = []
                collection?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    if steps > 0 {
                        summaries.append(
                            DailyStepSummary(
                                id: statistics.startDate,
                                dayStart: statistics.startDate,
                                steps: steps
                            )
                        )
                    }
                }

                summaries.sort { $0.dayStart > $1.dayStart }
                continuation.resume(returning: summaries)
            }

            store.execute(query)
        }
    }

    func fetchSamples(on day: Date) async throws -> [StepSampleRecord] {
        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }

        try await requestAuthorization()

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: day)
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let appBundleID = Bundle.main.bundleIdentifier

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let records = (samples as? [HKQuantitySample] ?? []).map { sample -> StepSampleRecord in
                    let steps = Int(sample.quantity.doubleValue(for: .count()))
                    let source = sample.sourceRevision.source
                    let bundleID = source.bundleIdentifier
                    let canDelete = bundleID == appBundleID
                    let isAppleSource = bundleID.hasPrefix("com.apple")
                    let device = sample.device

                    return StepSampleRecord(
                        id: sample.uuid,
                        steps: steps,
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        sourceName: source.name,
                        canDelete: canDelete,
                        isAppleSource: isAppleSource,
                        creationDate: sample.startDate,
                        deviceName: device?.name,
                        deviceManufacturer: device?.manufacturer,
                        deviceModel: device?.model,
                        deviceHardwareVersion: device?.hardwareVersion,
                        deviceSoftwareVersion: device?.softwareVersion,
                        sample: sample
                    )
                }
                continuation.resume(returning: records)
            }

            store.execute(query)
        }
    }

    func deleteSample(_ record: StepSampleRecord) async throws {
        guard record.canDelete else {
            throw HealthKitError.deleteFailed(
                String(localized: "Only records written by this app can be deleted.")
            )
        }

        do {
            try await store.delete(record.sample)
        } catch {
            throw HealthKitError.deleteFailed(error.localizedDescription)
        }
    }

    func deleteSamples(_ records: [StepSampleRecord]) async throws {
        let deletable = records.filter(\.canDelete)
        guard !deletable.isEmpty else {
            throw HealthKitError.deleteFailed(
                String(localized: "Only records written by this app can be deleted.")
            )
        }

        do {
            try await store.delete(deletable.map(\.sample))
        } catch {
            throw HealthKitError.deleteFailed(error.localizedDescription)
        }
    }
}
