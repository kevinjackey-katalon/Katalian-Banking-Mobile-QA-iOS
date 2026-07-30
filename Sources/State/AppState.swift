import Foundation
import Combine

/// Mirrors the top-level state + handlers in App.tsx.
/// `users` and `currentUser` are persisted the same way the web app persists
/// to localStorage (`katalian_users_v1` / `katalian_session_v1`), just backed
/// by UserDefaults instead of the browser.
@MainActor
final class AppState: ObservableObject {

    private enum StorageKeys {
        static let users = "katalian_users_v1"
        static let session = "katalian_session_v1"
    }

    @Published var users: [User] {
        didSet { persistUsers() }
    }
    @Published var currentUser: User? {
        didSet { persistSession() }
    }

    /// Path stack for the authenticated area (mirrors react-router's history).
    @Published var path: [AppRoute] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.users),
           let decodedUsers = try? JSONDecoder.katalian.decode([User].self, from: data) {
            self.users = decodedUsers
        } else {
            self.users = Constants.seedUsers
        }

        if let data = UserDefaults.standard.data(forKey: StorageKeys.session),
           let decodedUser = try? JSONDecoder.katalian.decode(User?.self, from: data) {
            self.currentUser = decodedUser
        } else {
            self.currentUser = nil
        }
    }

    private func persistUsers() {
        if let data = try? JSONEncoder.katalian.encode(users) {
            UserDefaults.standard.set(data, forKey: StorageKeys.users)
        }
    }

    private func persistSession() {
        if let currentUser, let data = try? JSONEncoder.katalian.encode(currentUser) {
            UserDefaults.standard.set(data, forKey: StorageKeys.session)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.session)
        }
    }

    // MARK: - Navigation

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goToDashboard() {
        path = []
    }

    // MARK: - Auth

    func login(username: String, password: String) -> LoginResult {
        guard let user = users.first(where: { $0.username == username }) else { return .invalid }
        if user.locked { return .locked }
        if user.passwordHash != password { return .invalid }
        currentUser = user
        goToDashboard()
        return .success
    }

    func logout() {
        currentUser = nil
        path = []
    }

    // MARK: - Security actions

    func completeSecurityAction(_ action: SecurityFinalAction) {
        guard let user = currentUser else { return }
        switch action {
        case .lockdown:
            var updated = user
            updated.locked = true
            updateUser(updated)
            logout()
        case .freezeAll:
            var updated = user
            updated.accounts = updated.accounts.map { acc in
                var acc = acc
                if acc.type.isCreditCard || acc.type == .checking {
                    acc.status = .frozen
                }
                return acc
            }
            updateUser(updated)
            goToDashboard()
        case .report:
            goToDashboard()
        }
    }

    // MARK: - Applications

    func submitApplication(_ appData: ApplicationData, accountType: Account.AccountType) async {
        guard let user = currentUser else { return }
        guard let newAccount = try? await MockAPI.submitApplication(userId: user.id, appData: appData, accountType: accountType) else { return }
        var updated = user
        updated.accounts.append(newAccount)
        updateUser(updated)
        goToDashboard()
    }

    func submitLoanApplication(_ loanData: LoanApplicationData, type: Loan.LoanType) async {
        guard let user = currentUser else { return }
        guard let newLoan = try? await MockAPI.submitLoanApplication(userId: user.id, loanData: loanData, type: type) else { return }
        var updated = user
        updated.loans.append(newLoan)
        updateUser(updated)
        goToDashboard()
    }

    // MARK: - Money movement

    func transfer(fromAccountId: String, toAccountId: String, amount: Double) async {
        guard let user = currentUser else { return }
        _ = try? await MockAPI.executeTransfer(fromId: fromAccountId, toId: toAccountId, amount: amount)

        guard user.accounts.contains(where: { $0.id == fromAccountId }),
              user.accounts.contains(where: { $0.id == toAccountId }) else { return }

        var updated = user
        updated.accounts = updated.accounts.map { acc in
            var acc = acc
            if acc.id == fromAccountId {
                acc.balance -= amount
            } else if acc.id == toAccountId {
                acc.balance += acc.type.isCreditCard ? -amount : amount
            }
            return acc
        }
        updateUser(updated)
        goToDashboard()
    }

    func deposit(toAccountId: String, amount: Double) async {
        guard let user = currentUser else { return }
        _ = try? await MockAPI.executeDeposit(toId: toAccountId, amount: amount)

        var updated = user
        updated.accounts = updated.accounts.map { acc in
            var acc = acc
            if acc.id == toAccountId { acc.balance += amount }
            return acc
        }
        updateUser(updated)
    }

    // MARK: - Helpers

    private func updateUser(_ updated: User) {
        currentUser = updated
        if let idx = users.firstIndex(where: { $0.id == updated.id }) {
            users[idx] = updated
        }
    }
}

extension JSONEncoder {
    static let katalian: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let katalian: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
