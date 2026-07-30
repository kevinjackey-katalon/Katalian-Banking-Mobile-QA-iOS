import SwiftUI
import PhotosUI

struct DepositView: View {
    @EnvironmentObject var appState: AppState

    private enum Method: String { case ach = "ACH", check = "Check" }

    private var user: User? { appState.currentUser }

    @State private var step = 1
    @State private var method: Method = .ach
    @State private var toAccountId = ""
    @State private var amountText = ""
    @State private var isLoading = false
    @State private var checkFrontPicked = false
    @State private var checkBackPicked = false

    private var toAccount: Account? { user?.accounts.first { $0.id == toAccountId } }
    private var canContinueFromStep2: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        if step == 2 && method == .check { return checkFrontPicked && checkBackPicked }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KStepProgressBar(progress: min(Double(step) / 3.0, 1))

                Text(isLoading ? "AUTHORIZING REQUEST" : (step == 4 ? "TRANSACTION COMPLETE" : "STEP \(step) OF 3"))
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(KTheme.emerald)

                if isLoading {
                    loadingCard
                } else {
                    KCard {
                        VStack(spacing: 24) {
                            stepContent
                            if step < 4 {
                                navigationButtons
                            }
                        }
                        .padding(28)
                    }
                }
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Deposit Facility")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if toAccountId.isEmpty { toAccountId = user?.accounts.first?.id ?? "" } }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: configStep
        case 2: fundingStep
        case 3: reviewStep
        case 4: successStep
        default: EmptyView()
        }
    }

    private var configStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Deposit Configuration").font(.system(size: 20, weight: .black)).foregroundColor(.white)
            Text("Define your funding source and capital amount.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)

            HStack(spacing: 12) {
                methodButton(.ach, icon: "🏛️", label: "Electronic Transfer")
                methodButton(.check, icon: "📄", label: "Check Deposit")
            }

            KPicker(label: "Destination Facility", selection: $toAccountId, options: (user?.accounts ?? []).map { ($0.id, "\($0.type.rawValue) - \($0.accountNumber)") })
            KTextField(label: "Provision Amount ($)", text: $amountText, placeholder: "0.00", keyboardType: .decimalPad)
        }
    }

    private func methodButton(_ m: Method, icon: String, label: String) -> some View {
        Button { method = m } label: {
            VStack(spacing: 8) {
                Text(icon).font(.system(size: 26))
                Text(label.uppercased()).font(.system(size: 9, weight: .black)).multilineTextAlignment(.center)
                    .foregroundColor(method == m ? KTheme.emerald : KTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(method == m ? KTheme.emerald.opacity(0.1) : KTheme.bgBase)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(method == m ? KTheme.emerald.opacity(0.4) : KTheme.border, lineWidth: 1))
        }
    }

    private var fundingStep: some View {
        Group {
            if method == .ach {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Funding Source").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                    Text("Verify the linked external account for this transaction.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                    VStack(spacing: 12) {
                        infoRow("Source Entity", "EXTERNAL PARTNER BANK")
                        infoRow("Account ID", "********5542")
                        infoRow("Availability", "Immediate Provisioning", valueColor: KTheme.emerald)
                    }
                    .padding(20)
                    .background(KTheme.emerald.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mobile Check Capture").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                    Text("Simulate uploading images of the check instrument.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                    HStack(spacing: 12) {
                        checkCaptureBox(label: "Check Front", picked: $checkFrontPicked)
                        checkCaptureBox(label: "Check Back", picked: $checkBackPicked)
                    }
                    Text("Ensure the back of the check is endorsed with \u{201C}For Mobile Deposit at Katalian Bank Only\u{201D}.")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(KTheme.textMuted)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func checkCaptureBox(label: String, picked: Binding<Bool>) -> some View {
        VStack(spacing: 8) {
            Text(label.uppercased()).font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
            Button { picked.wrappedValue = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: picked.wrappedValue ? "checkmark.circle.fill" : "camera")
                        .font(.system(size: 26))
                        .foregroundColor(picked.wrappedValue ? KTheme.emerald : KTheme.textMuted)
                    Text(picked.wrappedValue ? "Captured" : "Capture Image")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(picked.wrappedValue ? KTheme.emerald : KTheme.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(KTheme.bgBase)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundColor(picked.wrappedValue ? KTheme.emerald.opacity(0.5) : KTheme.border))
            }
        }
    }

    private var reviewStep: some View {
        VStack(spacing: 20) {
            Text("Final Authorization").font(.system(size: 20, weight: .black)).foregroundColor(.white)
            Text("Review asset allocation before ledger commitment.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)

            VStack(spacing: 4) {
                Text("LEDGER AMOUNT").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
                Text(currency(Double(amountText) ?? 0)).font(.system(size: 34, weight: .black)).foregroundColor(.white)
            }
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) { Divider().overlay(KTheme.border) }

            VStack(spacing: 10) {
                infoRow("Target Facility", "\(toAccount?.type.rawValue ?? "") ..\(String((toAccount?.accountNumber ?? "").suffix(4)))")
                infoRow("Submission Method", method == .ach ? "Priority ACH" : "Remote Image Capture", valueColor: KTheme.emerald)
                if method == .check {
                    infoRow("Image Verification", "Passed (Simulated)", valueColor: KTheme.emerald)
                }
            }
        }
        .padding(20)
        .background(KTheme.bgBase.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var successStep: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(KTheme.emerald.opacity(0.1)).frame(width: 90, height: 90)
                    .overlay(Circle().stroke(KTheme.emerald.opacity(0.2), lineWidth: 1))
                Image(systemName: "checkmark").font(.system(size: 32, weight: .bold)).foregroundColor(KTheme.emerald)
            }
            Text("Deposit Confirmed").font(.system(size: 26, weight: .black)).foregroundColor(.white)
            Text(method == .check
                 ? "Your check image has been queued for clearing. Funds will be provisioned following standard verification protocols."
                 : "Funds have been successfully provisioned to your \(toAccount?.type.rawValue ?? "") account.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(KTheme.textMuted)
                .multilineTextAlignment(.center)
            KButton(title: "Return to Portfolio") { appState.goToDashboard() }
        }
        .padding(.vertical, 20)
    }

    private var navigationButtons: some View {
        HStack {
            if step > 1 {
                KButton(title: "Back", variant: .secondary) { step -= 1 }
            }
            Spacer()
            if step < 3 {
                KButton(title: "Continue", isDisabled: !canContinueFromStep2) { step += 1 }
            } else {
                KButton(title: "Authorize Deposit") { submit() }
            }
        }
    }

    private var loadingCard: some View {
        KCard {
            VStack(spacing: 20) {
                KSpinner()
                Text(method == .check ? "Processing Image Data" : "Validating Liquidity Source")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
                Text(method == .check ? "Extracting metadata and routing numbers…" : "Establishing secure handshake with external institution…")
                    .font(.system(size: 12))
                    .foregroundColor(KTheme.textMuted)
            }
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity)
        }
    }

    private func infoRow(_ label: String, _ value: String, valueColor: Color = .white) -> some View {
        HStack {
            Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(KTheme.textMuted)
            Spacer()
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(valueColor)
        }
    }

    private func submit() {
        guard let amount = Double(amountText) else { return }
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await appState.deposit(toAccountId: toAccountId, amount: amount)
            isLoading = false
            step = 4
        }
    }
}
