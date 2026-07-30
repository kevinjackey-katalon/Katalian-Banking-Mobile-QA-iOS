import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    private var user: User? { appState.currentUser }

    private var totalBalance: Double {
        user?.accounts.reduce(0) { $0 + $1.balance } ?? 0
    }

    private struct ApplyOption {
        let label: String
        let type: Account.AccountType
        let icon: String
        let requiresPlatinum: Bool
    }

    private let applyOptions: [ApplyOption] = [
        .init(label: "Checking", type: .checking, icon: "💳", requiresPlatinum: false),
        .init(label: "Savings", type: .savings, icon: "💰", requiresPlatinum: false),
        .init(label: "Credit", type: .creditCard, icon: "💳", requiresPlatinum: false),
        .init(label: "Platinum", type: .platinumCreditCard, icon: "💎", requiresPlatinum: true),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                heroCard
                accountsSection
                applySection
                sidebarSection
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Portfolio")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Logout") { appState.logout() }
                    .foregroundColor(KTheme.emerald)
                    .font(.system(size: 13, weight: .bold))
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("NET LIQUIDITY")
                .font(.system(size: 10, weight: .black))
                .tracking(3)
                .foregroundColor(KTheme.textMuted)

            Text(currency(totalBalance))
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)

            HStack(spacing: 10) {
                Tag(text: "ACTIVE ASSETS", color: KTheme.emerald)
                Tag(text: "MEMBER SINCE 2021", color: KTheme.textMuted)
            }

            HStack(spacing: 12) {
                KButton(title: "Move Funds") { appState.navigate(to: .transfer) }
                KButton(title: "Deposit", variant: .secondary) { appState.navigate(to: .deposit) }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [KTheme.bgCard, KTheme.bgBase], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.border, lineWidth: 1))
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Accounts & Cards")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(user?.accounts ?? []) { account in
                    AccountCard(account: account) {
                        if account.status != .frozen {
                            appState.navigate(to: .accountDetails(accountId: account.id))
                        }
                    }
                }
            }
        }
    }

    private var applySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Apply for New Products")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(applyOptions, id: \.type) { opt in
                    if !opt.requiresPlatinum || (user?.canApplyForPlatinum ?? false) {
                        Button {
                            appState.navigate(to: .apply(accountType: opt.type))
                        } label: {
                            VStack(spacing: 10) {
                                Text(opt.icon).font(.system(size: 32))
                                Text(opt.label)
                                    .font(.system(size: 11, weight: .black))
                                    .textCase(.uppercase)
                                    .foregroundColor(KTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(KTheme.border, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private var sidebarSection: some View {
        VStack(spacing: 20) {
            KCard {
                VStack(spacing: 6) {
                    Text("ASSET MANAGEMENT")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(KTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)

                    QuickLink(label: "Document Library", icon: "📚") { appState.navigate(to: .documentLibrary) }
                    QuickLink(label: "Request Lending", icon: "🏛️") { appState.navigate(to: .loans) }
                    QuickLink(label: "Freeze All Cards", icon: "❄️") { appState.navigate(to: .security(action: .freezeAll)) }
                    QuickLink(label: "Fraud Reporting", icon: "🛡️") { appState.navigate(to: .contact) }
                    QuickLink(label: "Help Center", icon: "📞") { appState.navigate(to: .contact) }
                }
                .padding(24)
            }

            Button {
                appState.navigate(to: .loans)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mortgage rates dropped to 5.2%")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(KTheme.bgBase)
                    Text("Exclusive refinancing options for existing Katalian members.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(KTheme.bgBase.opacity(0.7))
                    Text("APPLY TODAY →")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())
                        .foregroundColor(KTheme.bgBase)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(KTheme.emerald)
                .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
            }
        }
    }
}

private struct Tag: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Rectangle().fill(Color.white.opacity(0.15)).frame(width: 40, height: 1)
        }
    }
}

private struct AccountCard: View {
    let account: Account
    var onTap: () -> Void

    var body: some View {
        let isFrozen = account.status == .frozen
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text(account.type.icon).font(.system(size: 26))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Spacer()
                    Text(account.accountNumber)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(KTheme.textMuted)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.type.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(KTheme.textMuted)
                    Text(currency(account.balance))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isFrozen ? KTheme.bgBase : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isFrozen ? KTheme.danger.opacity(0.25) : KTheme.border, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if isFrozen {
                    Text("FROZEN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(KTheme.dangerDark)
                        .clipShape(Capsule())
                        .padding(12)
                }
            }
        }
        .disabled(isFrozen)
        .opacity(isFrozen ? 0.75 : 1)
    }
}

private struct QuickLink: View {
    let label: String
    let icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon).font(.system(size: 20))
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(KTheme.textMuted)
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
