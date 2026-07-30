import SwiftUI

struct ContactView: View {
    @EnvironmentObject var appState: AppState

    private struct ChatMessage: Identifiable { let id = UUID(); let isUser: Bool; let text: String }

    @State private var messages: [ChatMessage] = [
        ChatMessage(isUser: false, text: "Welcome to Katalian Support. I am your personal concierge assistant. How may I facilitate your request today?")
    ]
    @State private var input = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Global Support").font(.system(size: 30, weight: .black)).foregroundColor(.white)
                    Text("Our concierge team is available around the clock to assist with your private wealth requirements.")
                        .font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    contactCard(icon: "📞", title: "Private Line", info: "1-800-KATALIAN", sub: "Priority Concierge 24/7")
                    contactCard(icon: "📧", title: "Secure Email", info: "wealth@katalian.com", sub: "Encrypted Communication")
                    contactCard(icon: "🏢", title: "Global HQ", info: "1200 Financial Plaza", sub: "New York, NY 10004")
                    contactCard(icon: "🕒", title: "Market Hours", info: "9AM – 5PM", sub: "EST (Mon–Fri)")
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Text("⚠️").font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Security Incident").font(.system(size: 16, weight: .black)).foregroundColor(KTheme.danger)
                            Text("Immediate actions for compromised accounts or stolen assets.")
                                .font(.system(size: 11)).foregroundColor(KTheme.textMuted)
                        }
                    }
                    HStack(spacing: 10) {
                        KButton(title: "Report Stolen Asset", variant: .danger, fullWidth: true) { appState.navigate(to: .security(action: .report)) }
                        KButton(title: "Account Lockdown", variant: .danger, fullWidth: true) { appState.navigate(to: .security(action: .lockdown)) }
                    }
                }
                .padding(20)
                .background(KTheme.danger.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(KTheme.danger.opacity(0.2), lineWidth: 1))

                chatCard
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func contactCard(icon: String, title: String, info: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(icon).font(.system(size: 28))
            Text(title.uppercased()).font(.system(size: 10, weight: .black)).foregroundColor(.white)
            Text(info).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(KTheme.emerald)
            Text(sub.uppercased()).font(.system(size: 8, weight: .black)).foregroundColor(KTheme.textMuted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(KTheme.border, lineWidth: 1))
    }

    private var chatCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(KTheme.emerald).frame(width: 8, height: 8)
                Text("WEALTH CONCIERGE").font(.system(size: 11, weight: .black)).foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(KTheme.bgBase.opacity(0.5))

            VStack(spacing: 12) {
                ForEach(messages) { m in
                    HStack {
                        if m.isUser { Spacer() }
                        Text(m.text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(m.isUser ? KTheme.bgBase : .white.opacity(0.85))
                            .padding(14)
                            .background(m.isUser ? KTheme.emerald : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .frame(maxWidth: 260, alignment: m.isUser ? .trailing : .leading)
                        if !m.isUser { Spacer() }
                    }
                }
            }
            .padding(16)

            HStack(spacing: 10) {
                TextField("Message Concierge…", text: $input)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(KTheme.bgBase)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Button { send() } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(KTheme.bgBase)
                        .padding(14)
                        .background(KTheme.emerald)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(16)
            .background(KTheme.bgBase.opacity(0.5))
        }
        .background(KTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.border, lineWidth: 1))
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(isUser: true, text: text))
        input = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var response = "I have noted your inquiry. A representative from our Private Banking division will be assigned to your case momentarily."
            let lower = text.lowercased()
            if lower.contains("card") { response = "Understood. For immediate card security, please use the Emergency Freeze options located in your Security dashboard or call 1-800-KATALIAN." }
            if lower.contains("loan") { response = "Our lending products are currently offering competitive rates. I can initiate a consultation request for you immediately." }
            messages.append(ChatMessage(isUser: false, text: response))
        }
    }
}
