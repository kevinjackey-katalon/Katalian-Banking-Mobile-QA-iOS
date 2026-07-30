import SwiftUI

struct ApplicationView: View {
    @EnvironmentObject var appState: AppState
    let accountType: Account.AccountType

    private var isDepositAccount: Bool { accountType == .checking || accountType == .savings }
    private var maxSteps: Int { isDepositAccount ? 3 : 2 }

    @State private var step = 1
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var lastName = ""
    @State private var dob = Date()
    @State private var address = ""
    @State private var city = ""
    @State private var state = Constants.states.first ?? "Ohio"
    @State private var zip = ""
    @State private var initialDeposit = ""
    @State private var depositFromAccountId = ""
    @State private var errors: [String: String] = [:]
    @State private var isProcessing = false
    @State private var isApproved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KStepProgressBar(progress: min(Double(step) / Double(maxSteps), 1))
                Text(isProcessing ? "PROCESSING" : (isApproved ? "APPROVED" : "PROVISIONING \(accountType.rawValue.uppercased())"))
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(KTheme.emerald)

                if isProcessing {
                    processingCard
                } else if isApproved {
                    successCard
                } else {
                    KCard {
                        VStack(spacing: 24) {
                            currentStepView
                            HStack {
                                if step > 1 {
                                    KButton(title: "Back", variant: .secondary) { step -= 1 }
                                }
                                Spacer()
                                if step < maxSteps {
                                    KButton(title: "Continue") { advance() }
                                } else {
                                    KButton(title: "Authorize Provisioning") { submit() }
                                }
                            }
                        }
                        .padding(28)
                    }
                }
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Katalian Products")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 1: identityStep
        case 2: residenceStep
        case 3: fundingStep
        default: EmptyView()
        }
    }

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Identity Verification").font(.system(size: 20, weight: .black)).foregroundColor(.white)
            Text("Please provide your legal credentials as they appear on official documents.")
                .font(.system(size: 13)).foregroundColor(KTheme.textMuted)
            KTextField(label: "Legal First Name", text: $firstName, errorMessage: errors["firstName"])
            KTextField(label: "Middle Name", text: $middleName)
            KTextField(label: "Legal Last Name", text: $lastName, errorMessage: errors["lastName"])
            DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .tint(KTheme.emerald)
        }
    }

    private var residenceStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Residence Information").font(.system(size: 20, weight: .black)).foregroundColor(.white)
            Text("Your primary physical address for regulatory compliance.")
                .font(.system(size: 13)).foregroundColor(KTheme.textMuted)
            KTextField(label: "Primary Address Line", text: $address, errorMessage: errors["address"])
            KTextField(label: "City", text: $city, errorMessage: errors["city"])
            KPicker(label: "State", selection: $state, options: Constants.states.map { ($0, $0) })
            KTextField(label: "Zip Code", text: $zip, keyboardType: .numberPad, errorMessage: errors["zip"])
        }
    }

    private var fundingStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Initial Asset Allocation").font(.system(size: 20, weight: .black)).foregroundColor(.white)
            Text("Set your starting liquidity for this new facility.")
                .font(.system(size: 13)).foregroundColor(KTheme.textMuted)
            KTextField(label: "Funding Amount ($)", text: $initialDeposit, placeholder: "0.00", keyboardType: .decimalPad)
            KPicker(label: "Transfer From Existing Account", selection: $depositFromAccountId,
                    options: [("", "External Wire / New Funds")] + (appState.currentUser?.accounts ?? []).filter { $0.type == .checking || $0.type == .savings }.map { ($0.id, "\($0.type.rawValue) (Ending \($0.accountNumber.suffix(4)))") })
        }
    }

    private var processingCard: some View {
        KCard {
            VStack(spacing: 20) {
                KSpinner()
                Text("Processing Credentials").font(.system(size: 17, weight: .black)).foregroundColor(.white)
                Text("Running regulatory background checks and risk assessment…")
                    .font(.system(size: 12)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
            }
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity)
        }
    }

    private var successCard: some View {
        KCard {
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(KTheme.emerald.opacity(0.1)).frame(width: 90, height: 90)
                        .overlay(Circle().stroke(KTheme.emerald.opacity(0.2), lineWidth: 1))
                    Image(systemName: "checkmark").font(.system(size: 32, weight: .bold)).foregroundColor(KTheme.emerald)
                }
                Text("Facility Approved").font(.system(size: 26, weight: .black)).foregroundColor(.white)
                Text("Your \(accountType.rawValue) has been successfully provisioned and is now available in your portfolio.")
                    .font(.system(size: 13)).foregroundColor(KTheme.textMuted).multilineTextAlignment(.center)
                KButton(title: "Enter Facility Dashboard") { finish() }
            }
            .padding(.vertical, 20)
        }
    }

    private func advance() {
        if validate(step: step) { step += 1 }
    }

    private func validate(step: Int) -> Bool {
        var newErrors: [String: String] = [:]
        if step == 1 {
            if firstName.trimmingCharacters(in: .whitespaces).isEmpty { newErrors["firstName"] = "Legal first name required." }
            if lastName.trimmingCharacters(in: .whitespaces).isEmpty { newErrors["lastName"] = "Legal last name required." }
        } else if step == 2 {
            if address.trimmingCharacters(in: .whitespaces).isEmpty { newErrors["address"] = "Primary residence required." }
            if city.trimmingCharacters(in: .whitespaces).isEmpty { newErrors["city"] = "City required." }
            if !(zip.count == 5 && zip.allSatisfy(\.isNumber)) { newErrors["zip"] = "Valid 5-digit ZIP code required." }
        }
        errors = newErrors
        return newErrors.isEmpty
    }

    private func submit() {
        guard validate(step: step) else { return }
        isProcessing = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isProcessing = false
            isApproved = true
        }
    }

    private func finish() {
        var appData = ApplicationData()
        appData.firstName = firstName
        appData.middleName = middleName
        appData.lastName = lastName
        appData.dob = dob
        appData.address = address
        appData.city = city
        appData.state = state
        appData.zip = zip
        appData.initialDeposit = Double(initialDeposit)
        appData.depositFromAccountId = depositFromAccountId.isEmpty ? nil : depositFromAccountId
        Task { await appState.submitApplication(appData, accountType: accountType) }
    }
}
