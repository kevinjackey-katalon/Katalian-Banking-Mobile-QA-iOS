import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.currentUser != nil {
                AuthenticatedRootView()
            } else {
                UnauthenticatedRootView()
            }
        }
    }
}

/// Login + password reset — mirrors the public routes in App.tsx.
private struct UnauthenticatedRootView: View {
    @State private var showResetPassword = false

    var body: some View {
        NavigationStack {
            LoginView(onShowReset: { showResetPassword = true })
                .navigationDestination(isPresented: $showResetPassword) {
                    PasswordResetView(onBackToLogin: { showResetPassword = false })
                }
        }
    }
}

/// Everything behind `ProtectedRoute` in App.tsx.
private struct AuthenticatedRootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack(path: $appState.path) {
            DashboardView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .overlay(alignment: .bottomTrailing) {
            AiAssistantView()
                .padding(24)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            DashboardView()
        case .documentLibrary:
            DocumentLibraryView()
        case .transfer:
            TransferView()
        case .deposit:
            DepositView()
        case .loans:
            LoansView()
        case .contact:
            ContactView()
        case .security(let action):
            SecurityView(action: action)
        case .accountDetails(let accountId):
            if let account = appState.currentUser?.accounts.first(where: { $0.id == accountId }) {
                AccountDetailsView(account: account)
            } else {
                DashboardView()
            }
        case .apply(let accountType):
            ApplicationView(accountType: accountType)
        case .applyLoan(let loanType):
            LoanApplicationView(loanType: loanType)
        case .admin:
            AdminView()
        }
    }
}
