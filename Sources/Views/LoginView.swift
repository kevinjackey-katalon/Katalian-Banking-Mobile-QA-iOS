import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    var onShowReset: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(KTheme.emerald.opacity(0.1))
                            .frame(width: 96, height: 96)
                            .overlay(Circle().stroke(KTheme.emerald.opacity(0.2), lineWidth: 1))
                        Image(systemName: "lock.shield")
                            .font(.system(size: 34, weight: .light))
                            .foregroundColor(KTheme.emerald)
                    }
                    VStack(spacing: 8) {
                        Text("KATALIAN")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                            .tracking(1)
                        Text("Private Banking & Asset Management")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(KTheme.textMuted)
                    }
                }
                .padding(.top, 60)

                KCard {
                    VStack(spacing: 24) {
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 11, weight: .black))
                                .textCase(.uppercase)
                                .multilineTextAlignment(.center)
                                .foregroundColor(KTheme.danger)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(KTheme.danger.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(KTheme.danger.opacity(0.2), lineWidth: 1))
                        }

                        VStack(spacing: 16) {
                            KTextField(label: "Secure ID", text: $username, placeholder: "USER_0000")
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            KTextField(label: "Access Code", text: $password, placeholder: "••••••••", isSecure: true)
                        }

                        KButton(title: isLoading ? "Authorizing…" : "Enter Vault Access", fullWidth: true, isDisabled: isLoading) {
                            submit()
                        }

                        Button("Lost Access Credentials?") {
                            onShowReset()
                        }
                        .font(.system(size: 10, weight: .black))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundColor(KTheme.textMuted)
                    }
                    .padding(32)
                }
                .padding(.horizontal, 4)

                Text("PROTECTED BY AES-256")
                    .font(.system(size: 10, weight: .black))
                    .tracking(4)
                    .foregroundColor(KTheme.textMuted.opacity(0.5))
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .kBackground()
    }

    private func submit() {
        errorMessage = nil
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            switch appState.login(username: username, password: password) {
            case .success: break
            case .invalid: errorMessage = "Authentication failed. Check Secure ID and Code."
            case .locked: errorMessage = "Account locked for security reasons."
            }
        }
    }
}
