import SwiftUI

struct RootView: View {
    @AppStorage("userNickname") private var nickname: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showWelcome = false
    @State private var selectedTab = 0
    @State private var showAddSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "chart.pie.fill", value: 0) {
                DashboardView(goToHistory: { selectedTab = 1 })
            }

            Tab("History", systemImage: "clock.arrow.circlepath", value: 1) {
                HistoryView()
            }

            // Tab "Add / Settings" terpisah dengan role .search — dibuka sebagai sheet
            Tab("Settings", systemImage: "gearshape.fill", value: 2, role: .search) {
                Color.clear
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                showAddSheet = true
                selectedTab = oldValue // Kembalikan ke tab sebelumnya
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddEntryHubView()
        }
        .onAppear {
            if !hasCompletedOnboarding { showWelcome = true }
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView {
                hasCompletedOnboarding = true
                showWelcome = false
            }
        }
    }
}
