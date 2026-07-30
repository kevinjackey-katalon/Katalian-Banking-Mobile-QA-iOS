import SwiftUI
import UIKit

@main
struct KatalianBankingApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Works around a long-standing SwiftUI bug where SecureField's masked
        // bullet glyphs don't reliably follow .tint()/.foregroundColor() set
        // via SwiftUI view modifiers and fall back to a default dark color —
        // invisible against this app's near-black field backgrounds. Setting
        // the UIKit appearance proxy directly reaches the actual UITextField
        // backing SecureField, so the cursor and secure-entry dots render white.
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
