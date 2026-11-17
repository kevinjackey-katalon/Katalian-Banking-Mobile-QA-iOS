import SwiftUI
import UIKit

@main
struct KatalianBankingApp: App {
    @StateObject private var appState = AppState()

    init() {
        // White caret and selection handles on the near-black field backgrounds.
        // (The password field is a UIKit UITextField with explicit colors; see
        // KSecureInput in Components.swift.)
        UITextField.appearance().tintColor = .white
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
