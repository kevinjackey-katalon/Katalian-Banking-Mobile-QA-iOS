import SwiftUI

struct TransferView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var user: User? { appState.currentUser }
    private var sourceAccounts: [Account] {
        (user?.accounts ?? []).filter { $0.type == .checking || $0.type == .savings }
    }
    private var recipientAccounts: [Account] { user?.accounts ?? [] }

    @State private var fromAccountId: String = ""
    @State private var toAccountId: String = ""
    @State private var amountText: String = ""
    @State private var errorMessage: String?
    @State private var isConfirming = false
    @State private var isSubmitting = false

    private var fromAccount: Account? { sourceAccounts.first { $0.id == fromAccountId } }
    private var toAccount: Account? { recipientAccounts.first { $0.id == toAccountId } }
    private var isCreditPayment: Bool { toAccount?.type.isCreditCard ?? false }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleBlock

                if isConfirming {
                    confirmationCard
                } else {
                    formCard
                }
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle(isCreditPayment ? "Credit Liquidation" : "Asset Movement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setupDefaults)
    }

    private var titleBlock: some View {
        Text(isConfirming ? "FINAL AUTHORIZATION" : (isCreditPayment ? "PAYMENT FACILITY" : "INTERNAL TRANSFER"))
            .font(.system(size: 11, weight: .black))
            .tracking(2)
            .foregroundColor(KTheme.emerald)
    }

    private var formCard: some View {
        KCard {
            VStack(spacing: 20) {
                if let errorMessage {
                    Text(errorMessage.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(KTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(KTheme.danger.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                KPicker(label: "Origin Liquidity", selection: $fromAccountId, options: sourceAccounts.map { ($0.id, "\($0.type.rawValue) (\($0.accountNumber)) — \(currency($0.balance))") })
                    .onChange(of: fromAccountId) { _, newValue in
                        if newValue == toAccountId, let fallback = recipientAccounts.first(where: { $0.id != newValue }) {
                            toAccountId = fallback.id
                        }
                    }

                Image(systemName: "arrow.down")
                    .foregroundColor(KTheme.emerald)
                    .padding(8)
                    .background(KTheme.bgCard)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(KTheme.border, lineWidth: 1))

                KPicker(label: isCreditPayment ? "Credit Facility Recipient" : "Recipient Facility", selection: $toAccountId, options: recipientAccounts.map { ($0.id, "\($0.type.rawValue) (\($0.accountNumber)) — \(currency($0.balance))") })

                if isCreditPayment, let toAccount {
                    creditPaymentHelper(toAccount)
                }

                KTextField(label: "Liquid Capital Amount", text: $amountText, placeholder: "0.00", keyboardType: .decimalPad)

                HStack(spacing: 12) {
                    KButton(title: "Cancel", variant: .ghost) { dismiss() }
                    KButton(title: "Review Protocol", fullWidth: true) { review() }
                }
            }
            .padding(28)
        }
    }

    private func creditPaymentHelper(_ toAccount: Account) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT INDEBTEDNESS").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
                    Text(currency(toAccount.balance)).font(.system(size: 20, weight: .black)).foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("CREDIT LIMIT").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
                    Text("$10,000.00").font(.system(size: 13, weight: .bold)).foregroundColor(KTheme.textMuted)
                }
            }
            HStack(spacing: 10) {
                Button("Min Payment ($25)") { amountText = "25.00" }
                Button("Pay Full Balance") { amountText = String(format: "%.2f", toAccount.balance) }
            }
            .font(.system(size: 10, weight: .black))
            .foregroundColor(KTheme.textMuted)
            .buttonStyle(.bordered)
        }
        .padding(18)
        .background(KTheme.emerald.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(KTheme.emerald.opacity(0.1), lineWidth: 1))
    }

    private var confirmationCard: some View {
        KCard {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("AMOUNT TO LIQUIDATE").font(.system(size: 10, weight: .black)).foregroundColor(KTheme.textMuted)
                    Text(currency(Double(amountText) ?? 0)).font(.system(size: 38, weight: .black)).foregroundColor(.white)
                }
                .padding(.bottom, 16)
                .overlay(alignment: .bottom) { Divider().overlay(KTheme.border) }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ORIGIN FACILITY").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
                        Text("\(fromAccount?.type.rawValue ?? "") \(fromAccount?.accountNumber ?? "")").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "arrow.right").foregroundColor(KTheme.emerald)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("RECIPIENT FACILITY").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
                        Text("\(toAccount?.type.rawValue ?? "") \(toAccount?.accountNumber ?? "")").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                }

                HStack(spacing: 12) {
                    KButton(title: "Back", variant: .secondary) { isConfirming = false }
                    KButton(title: isSubmitting ? "Authorizing…" : "Authorize \(isCreditPayment ? "Payment" : "Transfer")", fullWidth: true, isDisabled: isSubmitting) {
                        confirm()
                    }
                }
            }
            .padding(28)
        }
    }

    private func setupDefaults() {
        if fromAccountId.isEmpty { fromAccountId = sourceAccounts.first?.id ?? "" }
        if toAccountId.isEmpty { toAccountId = recipientAccounts.first(where: { $0.id != fromAccountId })?.id ?? "" }
    }

    private func review() {
        errorMessage = nil
        guard let amount = Double(amountText), amount > 0 else {
            errorMessage = "Valid capital amount required."
            return
        }
        guard !fromAccountId.isEmpty, !toAccountId.isEmpty else {
            errorMessage = "Please select both origin and destination facilities."
            return
        }
        guard fromAccountId != toAccountId else {
            errorMessage = "Self-transfer to identical facility is prohibited."
            return
        }
        guard let fromAccount, amount <= fromAccount.balance else {
            errorMessage = "Insufficient liquidity in origin facility."
            return
        }
        isConfirming = true
    }

    private func confirm() {
        guard let amount = Double(amountText) else { return }
        isSubmitting = true
        Task {
            await appState.transfer(fromAccountId: fromAccountId, toAccountId: toAccountId, amount: amount)
            isSubmitting = false
        }
    }
}
