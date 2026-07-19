import SwiftUI

struct SampleDetailView: View {
    let record: StepSampleRecord

    var body: some View {
        List {
            Section {
                detailRow(
                    title: String(localized: "Walking"),
                    value: "\(record.steps.formatted(.number.grouping(.automatic))) \(String(localized: "steps"))"
                )
                detailRow(
                    title: String(localized: "Start"),
                    value: record.startDate.formatted(detailDateTimeFormat)
                )
                detailRow(
                    title: String(localized: "End"),
                    value: record.endDate.formatted(detailDateTimeFormat)
                )
                detailRow(
                    title: String(localized: "Source"),
                    value: record.sourceName
                )
                if let creationDate = record.creationDate {
                    detailRow(
                        title: String(localized: "Date Added to Health"),
                        value: creationDate.formatted(detailDateTimeFormat)
                    )
                }
            } header: {
                Text("Sample Details")
            }

            if hasDeviceInfo {
                Section {
                    if let name = record.deviceName {
                        detailRow(title: String(localized: "Name"), value: name)
                    }
                    if let manufacturer = record.deviceManufacturer {
                        detailRow(title: String(localized: "Manufacturer"), value: manufacturer)
                    }
                    if let model = record.deviceModel {
                        detailRow(title: String(localized: "Model"), value: model)
                    }
                    if let hardware = record.deviceHardwareVersion {
                        detailRow(title: String(localized: "Hardware Version"), value: hardware)
                    }
                    if let software = record.deviceSoftwareVersion {
                        detailRow(title: String(localized: "Software Version"), value: software)
                    }
                } header: {
                    Text("Device Details")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hasDeviceInfo: Bool {
        record.deviceName != nil
            || record.deviceManufacturer != nil
            || record.deviceModel != nil
            || record.deviceHardwareVersion != nil
            || record.deviceSoftwareVersion != nil
    }

    private var detailDateTimeFormat: Date.FormatStyle {
        .dateTime.year().month().day().hour().minute().second()
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}
