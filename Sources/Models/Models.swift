import Foundation

// MARK: - Transaction

struct Transaction: Identifiable, Codable, Equatable {
    enum Kind: String, Codable { case credit = "Credit", debit = "Debit" }

    var id: String
    var date: Date
    var description: String
    var amount: Double
    var type: Kind
    var category: String
}

// MARK: - Account

struct Account: Identifiable, Codable, Equatable {
    enum AccountType: String, Codable, CaseIterable {
        case checking = "Checking"
        case savings = "Savings"
        case creditCard = "Credit Card"
        case platinumCreditCard = "Platinum Credit Card"

        var icon: String {
            switch self {
            case .checking: return "💳"
            case .savings: return "💰"
            case .creditCard: return "💳"
            case .platinumCreditCard: return "💎"
            }
        }

        var isCreditCard: Bool { self == .creditCard || self == .platinumCreditCard }
    }

    enum Status: String, Codable { case pending = "Pending", active = "Active", frozen = "Frozen" }

    var id: String
    var type: AccountType
    var accountNumber: String
    var balance: Double
    var status: Status?
    var transactions: [Transaction]
}

// MARK: - Loan

struct Loan: Identifiable, Codable, Equatable {
    enum LoanType: String, Codable, CaseIterable { case personal = "Personal", auto = "Auto", mortgage = "Mortgage" }
    enum Status: String, Codable { case pending = "Pending", approved = "Approved", active = "Active" }

    var id: String
    var type: LoanType
    var amount: Double
    var interestRate: Double
    var status: Status
    var termMonths: Int
}

// MARK: - User

struct User: Identifiable, Codable, Equatable {
    var id: String
    var username: String
    var passwordHash: String
    var accounts: [Account]
    var loans: [Loan]
    var canApplyForPlatinum: Bool
    var locked: Bool
    var unlockPasswordHash: String?
}

// MARK: - Application data (new account)

struct ApplicationData: Equatable {
    var firstName: String = ""
    var middleName: String = ""
    var lastName: String = ""
    var dob: Date = Date()
    var address: String = ""
    var city: String = ""
    var state: String = Constants.states.first ?? "Ohio"
    var zip: String = ""
    var initialDeposit: Double? = nil
    var depositFromAccountId: String? = nil
}

// MARK: - Loan application data

struct LoanApplicationData: Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var dob: Date = Date()
    var address: String = ""
    var city: String = ""
    var state: String = Constants.states.first ?? "Ohio"
    var zip: String = ""
    var employer: String = ""
    var jobTitle: String = ""
    var annualIncome: Double = 0
    var loanAmount: Double = 0
    var loanTerm: Int = 12
    var purpose: String = ""
}

// MARK: - Navigation

/// Mirrors the `ViewType` union from the web app's App.tsx / router.
enum AppRoute: Hashable {
    case dashboard
    case documentLibrary
    case transfer
    case deposit
    case loans
    case contact
    case security(action: SecurityAction)
    case accountDetails(accountId: String)
    case apply(accountType: Account.AccountType)
    case applyLoan(loanType: Loan.LoanType)
    case admin
}

enum SecurityAction: String, Hashable { case report, lockdown, freezeAll = "freeze-all" }

enum LoginResult { case success, locked, invalid }
enum SecurityFinalAction { case report, lockdown, freezeAll }
