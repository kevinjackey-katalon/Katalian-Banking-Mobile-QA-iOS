import SwiftUI

struct LoanApplicationView: View {
    @EnvironmentObject var appState: AppState
    let loanType: Loan.LoanType

    @State private var step = 1
    @State private var isLoading = false

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob = Date()
    @State private var address = ""
    @State private var employer = ""
    @State private var jobTitle = ""
    @State private var annualIncome = ""
    @State private var loanAmount = ""
    @State private var loanTerm = 12
    @State private var purpose = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KStepProgressBar(progress: min(Double(step) / 3.0, 1))
                Text(isLoading ? "PROCESSING" : "STEP \(step) OF 3")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(KTheme.emerald)

                if isLoading {
                    KCard {
                        VStack(spacing: 20) {
                            KSpinner()
                            Text("Running Risk Profile").font(.system(size: 17, weight: .black)).foregroundColor(.white)
                        }
                        .padding(.vertical, 60)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    KCard {
                        VStack(spacing: 24) {
                            currentStepView
                            HStack {
                                if step > 1 { KButton(title: "Back", variant: .secondary) { step -= 1 } }
                                Spacer()
                                if step < 3 {
                                    KButton(title: "Continue") { step += 1 }
                                } else {
                                    KButton(title: "Submit Application") { submit() }
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
        .navigationTitle("\(loanType.rawValue) Facility")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 1:
            VStack(alignment: .leading, spacing: 18) {
                Text("Personal Verification").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text("Verify your identity for the lending institution.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                KTextField(label: "First Name", text: $firstName)
                KTextField(label: "Last Name", text: $lastName)
                DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    .foregroundColor(.white).tint(KTheme.emerald)
                KTextField(label: "Primary Residence", text: $address)
            }
        case 2:
            VStack(alignment: .leading, spacing: 18) {
                Text("Capital & Employment").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text("Verify your income sources for risk assessment.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                KTextField(label: "Current Employer", text: $employer)
                KTextField(label: "Job Title", text: $jobTitle)
                KTextField(label: "Annual Income ($)", text: $annualIncome, keyboardType: .decimalPad)
            }
        case 3:
            VStack(alignment: .leading, spacing: 18) {
                Text("Facility Requirements").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text("Define repayment and utilization parameters.").font(.system(size: 13)).foregroundColor(KTheme.textMuted)
                KTextField(label: "Required Amount ($)", text: $loanAmount, keyboardType: .decimalPad)
                KPicker(label: "Proposed Term", selection: $loanTerm, options: [(12, "12 Months"), (24, "24 Months"), (36, "36 Months")])
                KTextField(label: "Purpose", text: $purpose, placeholder: "Description of capital utilization…")
            }
        default: EmptyView()
        }
    }

    private func submit() {
        isLoading = true
        var data = LoanApplicationData()
        data.firstName = firstName
        data.lastName = lastName
        data.dob = dob
        data.address = address
        data.employer = employer
        data.jobTitle = jobTitle
        data.annualIncome = Double(annualIncome) ?? 0
        data.loanAmount = Double(loanAmount) ?? 0
        data.loanTerm = loanTerm
        data.purpose = purpose
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await appState.submitLoanApplication(data, type: loanType)
            isLoading = false
        }
    }
}
