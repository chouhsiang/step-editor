import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case invalidStepCount
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "此裝置不支援健康資料（HealthKit）。"
        case .authorizationDenied:
            return "尚未授權寫入步數，請到「設定 > 健康 > 資料取用與裝置」開啟權限。"
        case .invalidStepCount:
            return "請輸入大於 0 的整數步數。"
        case .saveFailed(let message):
            return "寫入失敗：\(message)"
        }
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

        refreshAuthorizationStatus()
        if !isAuthorized {
            try await requestAuthorization()
        }

        let quantity = HKQuantity(unit: .count(), doubleValue: Double(steps))
        let sample = HKQuantitySample(
            type: stepType,
            quantity: quantity,
            start: date,
            end: date
        )

        do {
            try await store.save(sample)
            statusMessage = "已新增 \(steps) 步到「健康」App"
        } catch {
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }
}
