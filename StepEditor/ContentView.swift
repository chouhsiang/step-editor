import SwiftUI

struct AppBrandToolbarLabel: View {
    var body: some View {
        HStack(spacing: 6) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            Text("Step Patch")
                .font(.subheadline.weight(.semibold))
        }
    }
}

struct ContentView: View {
    @StateObject private var healthKit = HealthKitManager()

    var body: some View {
        TabView {
            StepsView()
                .tabItem {
                    Label("Steps", systemImage: "figure.walk")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .environmentObject(healthKit)
    }
}

#Preview {
    ContentView()
}
