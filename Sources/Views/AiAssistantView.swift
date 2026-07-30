import SwiftUI

/// Mirrors components/common/AiAssistant.tsx. The web version calls the Gemini
/// API with the full user database as context; this mobile version answers
/// the same class of questions (balances, accounts, totals) locally against
/// AppState so the assistant works fully offline in the QA build.
struct AiAssistantView: View {
    @EnvironmentObject var appState: AppState
    @State private var isOpen = false
    @State private var query = ""
    @State private var response: String?
    @State private var isLoading = false

    var body: some View {
        Group {
            if isOpen {
                panel
            } else {
                Button {
                    isOpen = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                        Text("Ask AI Assistant").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(KTheme.cyan)
                    .clipShape(Capsule())
                    .shadow(radius: 8)
                }
            }
        }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Katalian Financial AI", systemImage: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button { isOpen = false } label: {
                    Image(systemName: "xmark").foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .background(KTheme.cyan.opacity(0.9))

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if response == nil && !isLoading {
                        Text("Ask me anything about your accounts, total balances, or recent activity.")
                            .font(.system(size: 12))
                            .italic()
                            .foregroundColor(KTheme.textMuted)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                    }
                    if isLoading {
                        VStack(spacing: 10) {
                            KSpinner(tint: KTheme.cyan)
                            Text("Analyzing bank data…").font(.system(size: 11)).foregroundColor(KTheme.cyan)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    }
                    if let response {
                        Text(response)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(16)
            }
            .frame(height: 260)
            .background(KTheme.bgBase.opacity(0.4))

            HStack(spacing: 8) {
                TextField("Ask a question…", text: $query)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(KTheme.bgBase)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Button { ask() } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(KTheme.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(16)
            .background(KTheme.bgCard)
        }
        .frame(width: 340)
        .background(KTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(KTheme.cyan.opacity(0.3), lineWidth: 1))
        .shadow(radius: 20)
    }

    private func ask() {
        let q = query
        isLoading = true
        response = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            response = answer(for: q)
            isLoading = false
            query = ""
        }
    }

    /// Simple local reasoning over the seeded user database — a stand-in for
    /// the Gemini call the web app makes, since the mobile QA build runs offline.
    private func answer(for question: String) -> String {
        let lower = question.lowercased()
        let users = appState.users

        if lower.contains("total") && (lower.contains("balance") || lower.contains("asset")) {
            let total = users.reduce(0) { $0 + $1.accounts.reduce(0) { $0 + $1.balance } }
            return "Across all \(users.count) users on file, total assets under management are \(currency(total))."
        }
        if lower.contains("locked") {
            let lockedUsers = users.filter { $0.locked }.map { $0.username }
            return lockedUsers.isEmpty ? "No accounts are currently locked." : "Locked accounts: \(lockedUsers.joined(separator: ", "))."
        }
        if let user = appState.currentUser {
            if lower.contains("balance") || lower.contains("how much") {
                let total = user.accounts.reduce(0) { $0 + $1.balance }
                return "Your combined balance across \(user.accounts.count) accounts is \(currency(total))."
            }
            if lower.contains("loan") {
                if user.loans.isEmpty { return "You have no active loan facilities on file." }
                let details = user.loans.map { "\($0.type.rawValue): \(currency($0.amount)) at \($0.interestRate)% (\($0.status.rawValue))" }
                return details.joined(separator: "\n")
            }
        }
        return "I've noted your inquiry. A representative from our Private Banking division will follow up shortly."
    }
}
