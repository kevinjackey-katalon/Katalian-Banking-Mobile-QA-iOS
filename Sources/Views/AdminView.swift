import SwiftUI

struct AdminView: View {
    @EnvironmentObject var appState: AppState
    @State private var users: [User] = []
    @State private var isLoading = true

    private var totalBankBalance: Double {
        users.reduce(0) { $0 + $1.accounts.reduce(0) { $0 + $1.balance } }
    }

    var body: some View {
        ScrollView {
            if isLoading {
                KSpinner().padding(.top, 80)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bank Administration").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                            Text("System-wide diagnostic and API control center").font(.system(size: 12)).foregroundColor(KTheme.textMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TOTAL BANK ASSETS").font(.system(size: 9, weight: .bold)).foregroundColor(KTheme.cyan)
                            Text(currency(totalBankBalance)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        }
                        .padding(14)
                        .background(KTheme.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(KTheme.cyan.opacity(0.4), lineWidth: 1))
                    }

                    ForEach(users) { user in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Circle().fill(KTheme.emerald).frame(width: 36, height: 36)
                                    .overlay(Text(String(user.username.prefix(1)).uppercased()).font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(user.username).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                    Text("UID: \(user.id)").font(.system(size: 10)).foregroundColor(KTheme.textMuted)
                                }
                                Spacer()
                                if user.locked {
                                    tag("LOCKED", color: KTheme.danger)
                                }
                                if user.canApplyForPlatinum {
                                    tag("PLATINUM", color: .purple)
                                }
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(user.accounts) { acc in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(acc.type.rawValue.uppercased()).font(.system(size: 9, weight: .bold)).foregroundColor(KTheme.textMuted)
                                        Text(currency(acc.balance)).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.white)
                                        Text("# \(acc.accountNumber)").font(.system(size: 9)).foregroundColor(KTheme.textMuted.opacity(0.7))
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(KTheme.bgBase.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(16)
                        .background(KTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(KTheme.border, lineWidth: 1))
                    }

                    KButton(title: "Back to Dashboard", variant: .secondary, fullWidth: true) { appState.goToDashboard() }
                }
                .padding(20)
            }
        }
        .kBackground()
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            users = (try? await MockAPI.getUsers()) ?? []
            isLoading = false
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}
