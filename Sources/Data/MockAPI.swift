import Foundation

/// Mirrors api/mockApi.ts — simulated network latency + fabricated responses.
/// No real backend; every "banking" operation here is client-side only, exactly
/// like the original AI Studio demo web app.
enum MockAPI {

    static func getUsers() async throws -> [User] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Constants.seedUsers
    }

    static func submitApplication(userId: String, appData: ApplicationData, accountType: Account.AccountType) async throws -> Account {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return Account(
            id: "acc-\(UUID().uuidString.prefix(9))",
            type: accountType,
            accountNumber: "...\(Int.random(in: 1000...9999))",
            balance: appData.initialDeposit ?? 0,
            status: accountType.isCreditCard ? .pending : .active,
            transactions: []
        )
    }

    static func executeTransfer(fromId: String, toId: String, amount: Double) async throws -> Bool {
        try await Task.sleep(nanoseconds: 800_000_000)
        return true
    }

    static func executeDeposit(toId: String, amount: Double) async throws -> Bool {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        return true
    }

    static func submitLoanApplication(userId: String, loanData: LoanApplicationData, type: Loan.LoanType) async throws -> Loan {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let rate: Double = type == .mortgage ? 6.45 : (type == .auto ? 4.25 : 5.99)
        return Loan(
            id: "loan-\(UUID().uuidString.prefix(9))",
            type: type,
            amount: loanData.loanAmount,
            interestRate: rate,
            status: .pending,
            termMonths: loanData.loanTerm
        )
    }
}
