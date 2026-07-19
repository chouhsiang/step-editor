import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Text("Step Patch")
                                .font(.title2.weight(.semibold))
                            Text("Add steps to the Health app")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }

                Section {
                    Link(destination: URL(string: "https://github.com/chouhsiang/step-patch")!) {
                        Label("GitHub open source project", systemImage: "link")
                    }
                    Text("This open-source project uses the MIT License. See GitHub for source code and docs.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Open Source")
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppBrandToolbarLabel()
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
