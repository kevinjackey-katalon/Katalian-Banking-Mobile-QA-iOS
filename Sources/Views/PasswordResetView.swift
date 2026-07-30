import SwiftUI

struct PasswordResetView: View {
    var onBackToLogin: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Password Reset")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.white)
            Text("If an account with that email exists, we have sent password reset instructions. (This is a simulated feature).")
                .font(.system(size: 14))
                .foregroundColor(KTheme.textMuted)
                .multilineTextAlignment(.center)
            KButton(title: "Back to Login", fullWidth: true) {
                onBackToLogin()
            }
        }
        .padding(32)
        .frame(maxWidth: 420)
        .background(KTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .kBackground()
        .navigationBarBackButtonHidden(true)
    }
}
