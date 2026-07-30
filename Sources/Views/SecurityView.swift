import SwiftUI

struct SecurityView: View {
    @EnvironmentObject var appState: AppState
    let action: SecurityAction

    @State private var step = 1
    @State private var isLoading = false
    @State private var selectedAssetId: String = ""
    @State private var incidentDescription = ""

    private var user: User? { appState.currentUser }
    private var accentColor: Color {
        switch action {
        case .lockdown: return KTheme.dangerDark
        case .freezeAll: return KTheme.cyan
        case .report: return KTheme.danger
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KStepProgressBar(progress: min(Double(step) / 3.0, 1), tint: accentColor)
                Text(statusLabel)
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(accentColor)

                KCard {
                    Group {
                        if isLoading {
                            loadingView
                        } else {
                            switch action {
                            case .report: reportFlow
                            case .freezeAll: freezeFlow
                            case .lockdown: lockdownFlow
                            }
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Security Protocol")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if selectedAssetId.isEmpty { selectedAssetId = user?.accounts.first?.id ?? "" } }
        .onChange(of: step) { _, newValue in
            if action == .lockdown && newValue == 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    appState.completeSecurityAction(.lockdown)
                }
            }
        }
    }

    private var statusLabel: String {
        if isLoading { return "ESTABLISHING BLOCK" }
        if step == 3 { return "OPERATION COMPLETE" }
        switch action {
        case .lockdown: return "CRITICAL ACTION NEEDED"
        case .freezeAll: return "CRYO-FREEZE PROTOCOL"
        case .report: return "INCIDENT MANAGEMENT"
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            KSpinner(tint: accentColor)
            Text(loadingTitle).font(.system(size: 17, weight: .black)).foregroundColor(accentColor)
            Text("Validating security signatures and notifying central bank…")
                .font(.system(size: 12)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    private var loadingTitle: String {
        switch action {
        case .lockdown: return "Terminating All Sessions"
        case .freezeAll: return "Deep-Freezing Card Facilities"
        case .report: return "Provisioning Asset Block"
        }
    }

    // MARK: - Report flow

    @ViewBuilder
    private var reportFlow: some View {
        switch step {
        case 1:
            VStack(alignment: .leading, spacing: 20) {
                Text("Asset Compromise Report").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text("Identify the specific facility that has been compromised.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                KPicker(label: "Affected Facility", selection: $selectedAssetId, options: (user?.accounts ?? []).map { ($0.id, "\($0.type.rawValue) (Ending \($0.accountNumber.suffix(4)))") })
                KTextField(label: "Incident Narrative", text: $incidentDescription, placeholder: "Describe the nature of the compromise…")
                HStack {
                    KButton(title: "Cancel", variant: .secondary) { appState.navigate(to: .contact) }
                    KButton(title: "Authorize Asset Freeze", variant: .danger, fullWidth: true, isDisabled: incidentDescription.trimmingCharacters(in: .whitespaces).isEmpty) { step = 2 }
                }
            }
        case 2:
            VStack(spacing: 20) {
                Text("🔒").font(.system(size: 40))
                Text("Confirm Asset Freeze").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text("You are about to freeze \(user?.accounts.first(where: { $0.id == selectedAssetId })?.type.rawValue ?? ""). This will block all incoming and outgoing electronic authorizations immediately.")
                    .font(.system(size: 13)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
                KButton(title: "Execute Freeze Protocol", variant: .danger, fullWidth: true) { confirm() }
                KButton(title: "Back to Selection", variant: .ghost) { step = 1 }
            }
        case 3:
            VStack(spacing: 20) {
                successIcon(color: KTheme.danger)
                Text("Asset Frozen").font(.system(size: 26, weight: .black)).foregroundColor(.white)
                Text("Technical block applied. Our fraud prevention squad will contact you within 15 minutes at your registered mobile number.")
                    .font(.system(size: 13)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
                KButton(title: "Back to Portfolio") { appState.completeSecurityAction(.report) }
            }
        default: EmptyView()
        }
    }

    // MARK: - Freeze-all flow

    @ViewBuilder
    private var freezeFlow: some View {
        let affected = (user?.accounts ?? []).filter { $0.type.isCreditCard || $0.type == .checking }
        switch step {
        case 1:
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("❄️").font(.system(size: 30))
                        Text("Cryo-Freeze Cards").font(.system(size: 20, weight: .black)).foregroundColor(KTheme.cyan)
                    }
                    Text("This will temporarily suspend all active cards and digital payment facilities. External ACH and Savings transfers will remain functional.")
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
                    FlowLayoutTags(items: affected.map { $0.type.rawValue })
                }
                .padding(20)
                .background(KTheme.cyan.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(KTheme.cyan.opacity(0.2), lineWidth: 1))

                KButton(title: "Authorize Cryo-Freeze", fullWidth: true) { confirm() }
                    .tint(KTheme.cyan)
                KButton(title: "Cancel Protocol", variant: .ghost) { appState.goToDashboard() }
            }
        case 3:
            VStack(spacing: 20) {
                successIcon(color: KTheme.cyan, systemName: "snowflake")
                Text("Facilities Suspended").font(.system(size: 26, weight: .black)).foregroundColor(.white)
                Text("All identified cards have been moved to deep-freeze status. You can reactivate them individually from the account details ledger.")
                    .font(.system(size: 13)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
                KButton(title: "Back to Portfolio") { appState.completeSecurityAction(.freezeAll) }
            }
        default: EmptyView()
        }
    }

    // MARK: - Lockdown flow

    @ViewBuilder
    private var lockdownFlow: some View {
        switch step {
        case 1:
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("☢️").font(.system(size: 30))
                        Text("Nuclear Lockdown").font(.system(size: 20, weight: .black)).foregroundColor(KTheme.danger)
                    }
                    Text("This procedure will terminate all active sessions, invalidate current access tokens, and freeze ALL financial facilities tied to this identity.\n\nTHIS ACTION IS IRREVERSIBLE VIA MOBILE INTERFACE.")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                }
                .padding(20)
                .background(KTheme.danger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(KTheme.danger.opacity(0.3), lineWidth: 2))

                KButton(title: "Initiate Global Lockdown", variant: .danger, fullWidth: true) { step = 2 }
                KButton(title: "Abort Procedure", variant: .ghost) { appState.navigate(to: .contact) }
            }
        case 2:
            VStack(spacing: 20) {
                Text("⚠️").font(.system(size: 40))
                Text("Final Warning").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                Text("Global ledger freeze will commence upon confirmation.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                KButton(title: "CONFIRM GLOBAL FREEZE", variant: .danger, fullWidth: true) { confirm() }
                KButton(title: "Back to Safety", variant: .secondary, fullWidth: true) { step = 1 }
            }
        case 3:
            VStack(spacing: 20) {
                successIcon(color: KTheme.dangerDark, systemName: "lock.fill")
                Text("System Locked").font(.system(size: 26, weight: .black)).foregroundColor(.white)
                Text("All digital facilities have been severed. You will be logged out shortly.")
                    .font(.system(size: 13)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
                KSpinner(tint: KTheme.dangerDark)
            }
        default: EmptyView()
        }
    }

    private func successIcon(color: Color, systemName: String = "checkmark") -> some View {
        ZStack {
            Circle().fill(color.opacity(0.12)).frame(width: 90, height: 90)
                .overlay(Circle().stroke(color.opacity(0.25), lineWidth: 1))
            Image(systemName: systemName).font(.system(size: 32, weight: .bold)).foregroundColor(color)
        }
    }

    private func confirm() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isLoading = false
            step = 3
        }
    }
}

/// Lightweight wrapping tag list (mirrors the flex-wrap facility badges in the web app).
private struct FlowLayoutTags: View {
    let items: [String]
    var body: some View {
        var uniqueItems: [String] { Array(Set(items)) }
        return HStack {
            ForEach(uniqueItems, id: \.self) { item in
                Text(item.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .foregroundColor(.white.opacity(0.7))
                    .clipShape(Capsule())
            }
        }
    }
}
