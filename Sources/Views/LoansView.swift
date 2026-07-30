import SwiftUI

struct LoansView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Private Credit Solutions")
                        .font(.system(size: 30, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Text("Sophisticated lending for your primary residence, luxury vehicles, or personal capital requirements.")
                        .font(.system(size: 14))
                        .foregroundColor(KTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                VStack(spacing: 20) {
                    ForEach(Constants.loanProducts) { product in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(product.icon).font(.system(size: 44))
                            Text(product.type.rawValue).font(.system(size: 24, weight: .black)).foregroundColor(.white)
                            Text(product.description).font(.system(size: 13, weight: .medium)).foregroundColor(KTheme.textMuted)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("RATES FROM").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.textMuted)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(product.rate).font(.system(size: 30, weight: .black)).foregroundColor(KTheme.emerald)
                                    Text("APR").font(.system(size: 10, weight: .black)).foregroundColor(KTheme.emerald.opacity(0.6))
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            KButton(title: "Apply for Funding", fullWidth: true) {
                                appState.navigate(to: .applyLoan(loanType: product.type))
                            }
                        }
                        .padding(24)
                        .background(KTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
                        .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.border, lineWidth: 1))
                    }
                }

                VStack(spacing: 12) {
                    Text("Need a custom lending solution?").font(.system(size: 18, weight: .black)).foregroundColor(.white)
                    Text("Contact our wealth management team for commercial facilities or high-limit liquidity lines.")
                        .font(.system(size: 13)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
                    KButton(title: "Contact Asset Division", variant: .secondary) { appState.navigate(to: .contact) }
                }
                .padding(28)
                .background(KTheme.emerald.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.emerald.opacity(0.15), lineWidth: 1))
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Lending")
        .navigationBarTitleDisplayMode(.inline)
    }
}
