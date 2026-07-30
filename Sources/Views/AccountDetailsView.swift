import SwiftUI

struct AccountDetailsView: View {
    @EnvironmentObject var appState: AppState
    let account: Account

    @State private var selectedMonth: String = "All"
    @State private var isGeneratingPDF = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    private var availableMonths: [String] {
        var months: [String] = []
        for tx in account.transactions {
            let m = DateFormatter.monthYear.string(from: tx.date)
            if !months.contains(m) { months.append(m) }
        }
        return ["All"] + months
    }

    private var filteredTransactions: [Transaction] {
        let sorted = account.transactions.sorted { $0.date > $1.date }
        if selectedMonth == "All" { return sorted }
        return sorted.filter { DateFormatter.monthYear.string(from: $0.date) == selectedMonth }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                monthFilterBar
                ledgerTable
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("\(account.type.rawValue) Ledger")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text(account.type.icon)
                    .font(.system(size: 30))
                    .frame(width: 64, height: 64)
                    .background(KTheme.emerald.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(KTheme.emerald.opacity(0.2), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(account.type.rawValue) Ledger")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                    Text("\(account.accountNumber) • SECURE FACILITY")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(KTheme.textMuted)
                }
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AVAILABLE CAPITAL")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(KTheme.textMuted)
                    Text(currency(account.balance))
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                }
                Spacer()
                KButton(title: isGeneratingPDF ? "Provisioning…" : "Statement", variant: .secondary, isDisabled: isGeneratingPDF) {
                    generateStatement()
                }
            }
            .padding(20)
            .background(KTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(KTheme.border, lineWidth: 1))
        }
    }

    private var monthFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableMonths, id: \.self) { month in
                    Button {
                        selectedMonth = month
                    } label: {
                        Text(month.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedMonth == month ? KTheme.emerald : Color.white.opacity(0.05))
                            .foregroundColor(selectedMonth == month ? KTheme.bgBase : KTheme.textMuted)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var ledgerTable: some View {
        VStack(spacing: 0) {
            if filteredTransactions.isEmpty {
                Text("No ledger entries detected for this period.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(KTheme.textMuted)
                    .padding(.vertical, 60)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(filteredTransactions) { tx in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(DateFormatter.shortDate.string(from: tx.date))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text(tx.category)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(KTheme.textMuted)
                        }
                        .frame(width: 90, alignment: .leading)

                        Text(tx.description)
                            .font(.system(size: 12, weight: .heavy))
                            .italic()
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text((tx.type == .credit ? "+" : "-") + currency(tx.amount))
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(tx.type == .credit ? KTheme.emerald : .white.opacity(0.9))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    Divider().overlay(KTheme.border)
                }
            }
        }
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(KTheme.border, lineWidth: 1))
    }

    private func generateStatement() {
        isGeneratingPDF = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let data = StatementPDF.makeStatement(account: account, transactions: filteredTransactions, period: selectedMonth == "All" ? "Complete History" : selectedMonth)
            let filename = "Katalian_Statement_\(account.type.rawValue.replacingOccurrences(of: " ", with: "_"))_\(selectedMonth.replacingOccurrences(of: " ", with: "_")).pdf"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? data.write(to: url)
            pdfURL = url
            isGeneratingPDF = false
            showShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
