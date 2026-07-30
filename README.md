# Katalian Banking — Mobile QA (iOS)

A native **SwiftUI** iOS app that mirrors the functionality of the
[Katalian-Banking-QA](https://github.com/kevinjackey-katalon/Katalian-Banking-QA)
web application, for use as a mobile QA / Katalon demo target (manual testing,
Katalon Studio mobile recorder, Appium/XCUITest automation, etc).

This is a fully client-side simulation — same as the original AI Studio web
app: there is no real backend, no real money movement, and no real
authentication. All "banking" operations are mocked with artificial network
delay to give automation and manual testers realistic async flows to exercise.

## Feature parity with the web app

| Web app screen | iOS equivalent | Notes |
|---|---|---|
| `LoginScreen.tsx` | `LoginView.swift` | Same seeded credentials, same locked-account flow |
| `DashboardScreen.tsx` | `DashboardView.swift` | Net liquidity hero, account cards, quick links |
| `AccountDetailsScreen.tsx` | `AccountDetailsView.swift` | Month filter + PDF statement export (PDFKit) |
| `TransferScreen.tsx` | `TransferView.swift` | 2-step transfer/credit-payment with confirmation |
| `DepositScreen.tsx` | `DepositView.swift` | ACH vs. Check deposit, 4-step flow |
| `ApplicationScreen.tsx` | `ApplicationView.swift` | Multi-step new account application |
| `LoansScreen.tsx` / `LoanApplicationScreen.tsx` | `LoansView.swift` / `LoanApplicationView.swift` | Loan catalogue + 3-step application |
| `ContactScreen.tsx` | `ContactView.swift` | Simulated concierge chat + security shortcuts |
| `SecurityScreen.tsx` | `SecurityView.swift` | Report / Freeze-All / Lockdown protocols |
| `DocumentLibraryScreen.tsx` | `DocumentLibraryView.swift` | Generates the same fillable Loan Request Form PDF |
| `AdminScreen.tsx` | `AdminView.swift` | User/balance diagnostic view |
| `AiAssistant.tsx` | `AiAssistantView.swift` | Floating assistant; answers balance/loan questions locally (no Gemini key bundled) |

### Seeded test accounts

| Username | Password | Notes |
|---|---|---|
| `bankinguser123` | `notapassword@123` | Standard user — Checking, Savings, Credit Card, Platinum-eligible |
| `lockedout25` | `lockedoutpassword343` | Locked account — exercises the "Account locked" login path |

### State & persistence

`AppState` mirrors the web app's `localStorage` usage: the user list and
current session are persisted via `UserDefaults` under
`katalian_users_v1` / `katalian_session_v1`, so app relaunches keep whatever
the tester changed (new accounts, frozen cards, locked users, etc) — same
behavior as a browser refresh in the web app.

## Project structure

```
KatalianBankingMobileQA/
├── project.yml                # XcodeGen spec — generates the .xcodeproj
├── Resources/
│   ├── Info.plist
│   └── Assets.xcassets/
└── Sources/
    ├── App/                   # App entry point + root router
    ├── Models/                # User/Account/Transaction/Loan models
    ├── Data/                  # Seed data + MockAPI
    ├── State/                 # AppState (observable, persisted)
    ├── Theme/                 # Colors + shared components (buttons, inputs, cards)
    ├── Utilities/             # PDF generation (statements, loan form)
    └── Views/                 # One SwiftUI view per screen
```

## Building the app

This repo ships **source only** (no committed `.xcodeproj`) and uses
[XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode
project deterministically from `project.yml`. This keeps the repo diff-clean
and avoids merge conflicts in `.pbxproj`.

1. Install XcodeGen (one-time):
   ```bash
   brew install xcodegen
   ```
2. Clone this repo and generate the project:
   ```bash
   git clone https://github.com/kevinjackey-katalon/Katalian-Banking-Mobile-QA-iOS.git
   cd Katalian-Banking-Mobile-QA-iOS
   xcodegen generate
   ```
3. Open `KatalianBankingMobileQA.xcodeproj` in Xcode (15+) and run on an
   iOS 17+ simulator or device.

### Alternative: create the project by hand in Xcode

If you'd rather not install XcodeGen:

1. In Xcode: **File → New → Project → iOS → App**. Name it
   `KatalianBankingMobileQA`, interface **SwiftUI**, language **Swift**,
   minimum deployment target **iOS 17**.
2. Delete the generated `ContentView.swift` and default `Assets.xcassets` if
   you want a clean slate, then drag the contents of this repo's `Sources/`
   folder into the project (checking "Copy items if needed").
3. Add `Resources/Info.plist` as the target's Info.plist, or merge its keys
   into the auto-generated one.
4. Build & run.

## Using this for Katalon mobile automation

This app is intended as a stable, self-contained target for:
- **Katalon Studio** mobile object capture / recording (iOS Simulator or
  physical device via Appium)
- **XCUITest**-based automation, since every interactive element uses plain
  SwiftUI controls (`Button`, `TextField`, `Picker`, etc.) with predictable
  accessibility identifiers derived from their visible text
- Manual QA walkthroughs of account opening, transfers, deposits, loan
  applications, and the security/fraud-reporting protocols

## Relationship to the Android sibling repo

This project is the iOS counterpart to
[Katalian-Banking-Mobile-QA-Android](https://github.com/kevinjackey-katalon/Katalian-Banking-Mobile-QA-Android),
built independently as a native SwiftUI app rather than a shared
cross-platform codebase, so each platform exercises its own native UI
automation stack.
