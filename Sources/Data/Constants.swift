import Foundation

enum Constants {

    static let states: [String] = [
        "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware",
        "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
        "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
        "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico",
        "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania",
        "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
        "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
    ]

    struct LoanProduct: Identifiable {
        var id: String { type.rawValue }
        let type: Loan.LoanType
        let rate: String
        let description: String
        let icon: String
    }

    static let loanProducts: [LoanProduct] = [
        LoanProduct(type: .personal, rate: "5.99%", description: "Flexible funds for life's unexpected moments.", icon: "💰"),
        LoanProduct(type: .auto, rate: "4.25%", description: "Get behind the wheel of your dream car faster.", icon: "🚗"),
        LoanProduct(type: .mortgage, rate: "6.45%", description: "Your journey to home ownership starts here.", icon: "🏠"),
    ]

    private static func generateMockTransactions(count: Int, baseDescription: String) -> [Transaction] {
        (0..<count).map { i in
            let isCredit = Double.random(in: 0...1) > 0.6
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.month = (comps.month ?? 1) - Int.random(in: 0...3)
            comps.day = Int.random(in: 1...28)
            let date = Calendar.current.date(from: comps) ?? Date()
            return Transaction(
                id: "tx-\(UUID().uuidString.prefix(9))",
                date: date,
                description: "\(baseDescription) \(i + 1)",
                amount: (Double.random(in: 10...510)).rounded(toPlaces: 2),
                type: isCredit ? .credit : .debit,
                category: isCredit ? "Income" : "General"
            )
        }
    }

    /// Seed users — mirrors USERS in constants.ts (bankinguser123 / lockedout25).
    static var seedUsers: [User] {
        let df = ISO8601DateFormatter()
        func d(_ s: String) -> Date { df.date(from: s) ?? Date() }

        let user1 = User(
            id: "user1",
            username: "bankinguser123",
            passwordHash: "notapassword@123",
            accounts: [
                Account(
                    id: "acc1-1", type: .checking, accountNumber: "...7890", balance: 5345.54, status: .active,
                    transactions: [
                        Transaction(id: "tx1", date: d("2025-05-10T10:00:00Z"), description: "Apple Store Cupertino", amount: 1299.00, type: .debit, category: "Technology"),
                        Transaction(id: "tx2", date: d("2025-05-08T14:30:00Z"), description: "Katalian Payroll Deposit", amount: 4500.00, type: .credit, category: "Salary"),
                        Transaction(id: "tx3", date: d("2025-04-25T12:00:00Z"), description: "Whole Foods Market", amount: 156.43, type: .debit, category: "Groceries"),
                    ] + generateMockTransactions(count: 12, baseDescription: "Point of Sale")
                ),
                Account(
                    id: "acc1-2", type: .savings, accountNumber: "...1234", balance: 104456.67, status: .active,
                    transactions: [
                        Transaction(id: "tx4", date: d("2025-05-01T00:00:00Z"), description: "Interest Credit", amount: 456.67, type: .credit, category: "Interest"),
                    ] + generateMockTransactions(count: 5, baseDescription: "Internal Transfer")
                ),
                Account(
                    id: "acc1-3", type: .creditCard, accountNumber: "...9921", balance: 1250.00, status: .active,
                    transactions: [
                        Transaction(id: "tx5", date: d("2025-05-12T10:00:00Z"), description: "Gas Station X", amount: 55.00, type: .debit, category: "Transport"),
                    ] + generateMockTransactions(count: 8, baseDescription: "Merchant Purchase")
                ),
            ],
            loans: [],
            canApplyForPlatinum: true,
            locked: false,
            unlockPasswordHash: nil
        )

        let user4 = User(
            id: "user4",
            username: "lockedout25",
            passwordHash: "lockedoutpassword343",
            accounts: [
                Account(
                    id: "acc4-1", type: .checking, accountNumber: "...3456", balance: 12.14, status: .active,
                    transactions: generateMockTransactions(count: 3, baseDescription: "Emergency Withdrawal")
                ),
            ],
            loans: [],
            canApplyForPlatinum: false,
            locked: true,
            unlockPasswordHash: "resetpassword@45"
        )

        return [user1, user4]
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
