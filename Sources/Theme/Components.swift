import SwiftUI
import UIKit

// MARK: - Helpers

extension String {
    /// Stable accessibility identifier derived from a visible label,
    /// e.g. "Access Code" -> "access_code".
    var kIdentifier: String {
        var out = ""
        var lastWasSeparator = false
        for ch in lowercased() {
            if ch.isASCII && (ch.isLetter || ch.isNumber) {
                out.append(ch)
                lastWasSeparator = false
            } else if !lastWasSeparator && !out.isEmpty {
                out.append("_")
                lastWasSeparator = true
            }
        }
        if out.hasSuffix("_") { out.removeLast() }
        return out
    }
}

enum KKeyboard {
    /// Dismisses whatever keyboard is currently showing.
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// "Done" button above the keyboard. Needed because .decimalPad / .numberPad
/// have no Return key. Add it ONCE per screen (see KBackground) - adding it to
/// every field would show duplicate buttons.
struct KKeyboardDoneToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") { KKeyboard.dismiss() }
                .accessibilityIdentifier("keyboard_done")
        }
    }
}

// MARK: - Button variants (mirrors components/common/Button.tsx)

enum KButtonVariant { case primary, secondary, ghost, danger }

struct KButton: View {
    var title: String
    var variant: KButtonVariant = .primary
    var fullWidth: Bool = false
    var isDisabled: Bool = false
    /// Stable accessibility identifier. Defaults to one derived from `title`;
    /// pass an explicit value when the title changes (e.g. "Authorizing…").
    var identifier: String? = nil
    var action: () -> Void

    @ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 15

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 16)
                .padding(.horizontal, 28)
        }
        .background(background)
        .foregroundColor(foreground)
        .overlay(
            RoundedRectangle(cornerRadius: KTheme.pillRadius)
                .stroke(border, lineWidth: variant == .secondary ? 1 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: KTheme.pillRadius))
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isDisabled)
        .accessibilityIdentifier(identifier ?? title.kIdentifier)
    }

    private var background: Color {
        switch variant {
        case .primary: return KTheme.emerald
        case .secondary: return Color.white.opacity(0.06)
        case .ghost: return .clear
        case .danger: return KTheme.dangerDark
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: return KTheme.bgBase
        case .secondary, .ghost: return KTheme.textPrimary
        case .danger: return .white
        }
    }

    private var border: Color {
        variant == .secondary ? KTheme.border : .clear
    }
}

// MARK: - Input kinds

/// What a text field is for. Each kind maps to the iOS-standard keyboard,
/// capitalization, autocorrect, content type (AutoFill) and input filter.
enum KInputKind {
    case text        // free-form single line: sentence caps, autocorrect on
    case name        // person / company names: word caps, no autocorrect
    case username    // login identifier: ASCII keyboard, no caps, no autocorrect
    case password    // real secure entry (see KSecureInput)
    case address     // street / city: word caps, no autocorrect
    case decimal     // currency: decimal pad, digits + one separator, 2 decimals
    case digits      // digits only (ZIP): number pad
    case multiline   // free-form multi-line narrative

    var keyboardType: UIKeyboardType {
        switch self {
        case .username: return .asciiCapable
        case .decimal: return .decimalPad
        case .digits: return .numberPad
        case .text, .name, .password, .address, .multiline: return .default
        }
    }

    var capitalization: TextInputAutocapitalization {
        switch self {
        case .name, .address: return .words
        case .username, .password, .decimal, .digits: return .never
        case .text, .multiline: return .sentences
        }
    }

    var allowsAutocorrect: Bool {
        switch self {
        case .text, .multiline: return true
        case .name, .username, .password, .address, .decimal, .digits: return false
        }
    }

    var defaultContentType: UITextContentType? {
        switch self {
        case .username: return .username
        case .password: return .password
        case .text, .name, .address, .decimal, .digits, .multiline: return nil
        }
    }

    /// Strips characters the kind can never contain (covers paste, which the
    /// number pads cannot prevent).
    func sanitize(_ input: String) -> String {
        switch self {
        case .decimal: return KInputKind.sanitizeDecimal(input)
        case .digits: return input.filter { $0.isASCII && $0.isNumber }
        case .text, .name, .username, .password, .address, .multiline: return input
        }
    }

    private static func sanitizeDecimal(_ input: String) -> String {
        var result = ""
        var seenSeparator = false
        var fractionDigits = 0
        for ch in input {
            if ch.isASCII && ch.isNumber {
                if seenSeparator {
                    if fractionDigits >= 2 { continue }
                    fractionDigits += 1
                }
                result.append(ch)
            } else if (ch == "." || ch == ",") && !seenSeparator {
                seenSeparator = true
                result.append(".")
            }
        }
        return result
    }
}

// MARK: - Input field (mirrors components/common/Input.tsx)
// NOTE: body is deliberately split into small named subviews with explicit
// `some View` return types. A single large expression here (nested
// HStack -> Group -> if/else -> Button -> ternaries) can cause the Swift
// type checker to time out in Release/whole-module builds ("unable to
// type-check this expression in reasonable time"), which fails the whole
// compile batch with no useful per-line diagnostic. Splitting it up avoids
// that class of failure entirely.
struct KTextField: View {
    var label: String
    @Binding var text: String
    var placeholder: String = ""
    var kind: KInputKind = .text
    /// Overrides the kind's default AutoFill content type (e.g. .givenName).
    var contentType: UITextContentType? = nil
    var errorMessage: String? = nil
    /// Stable accessibility identifier. Defaults to one derived from `label`.
    var identifier: String? = nil
    var maxLength: Int? = nil
    var submitLabel: SubmitLabel = .next
    /// Called when the keyboard's Return key is pressed.
    var onReturn: (() -> Void)? = nil
    /// Password fields only: set to true to move keyboard focus into the field.
    var focusRequest: Binding<Bool>? = nil

    /// Local reveal state for password fields - toggled by the eye button below.
    /// Purely a display concern; the bound `text` value is unaffected either way.
    @State private var isRevealed = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 15
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 10
    @ScaledMetric(relativeTo: .caption) private var errorSize: CGFloat = 11

    private var fieldID: String { identifier ?? label.kIdentifier }
    private var effectiveContentType: UITextContentType? { contentType ?? kind.defaultContentType }
    private var promptText: Text { Text(placeholder).foregroundColor(Color.white.opacity(0.5)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelText
            fieldRow
            errorText
        }
    }

    private var labelText: some View {
        Text(label)
            .font(.system(size: labelSize, weight: .black))
            .textCase(.uppercase)
            .tracking(1.5)
            .foregroundColor(KTheme.textMuted)
            .padding(.leading, 4)
            // The field itself carries this label as its accessible name.
            .accessibilityHidden(true)
    }

    private var fieldRow: some View {
        HStack(spacing: 0) {
            inputField
                .padding(.vertical, 16)
                .padding(.leading, 16)
                .padding(.trailing, kind == .password ? 4 : 16)
            if kind == .password {
                revealToggleButton
            }
        }
        .background(KTheme.bgBase)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(fieldBorder)
    }

    @ViewBuilder
    private var inputField: some View {
        switch kind {
        case .password:
            secureInput
        case .multiline:
            multilineField
        case .text, .name, .username, .address, .decimal, .digits:
            singleLineField
        }
    }

    private var singleLineField: some View {
        TextField(label, text: $text, prompt: promptText)
            .keyboardType(kind.keyboardType)
            .textInputAutocapitalization(kind.capitalization)
            .autocorrectionDisabled(!kind.allowsAutocorrect)
            .textContentType(effectiveContentType)
            .submitLabel(submitLabel)
            .onSubmit { onReturn?() }
            .font(.system(size: bodySize, weight: .semibold))
            .foregroundColor(.white)
            .accessibilityLabel(label)
            .accessibilityHint(errorMessage ?? "")
            .accessibilityIdentifier(fieldID)
            .onChange(of: text) { _, newValue in applyFilter(newValue) }
    }

    private var multilineField: some View {
        TextField(label, text: $text, prompt: promptText, axis: .vertical)
            .lineLimit(3...6)
            .keyboardType(kind.keyboardType)
            .textInputAutocapitalization(kind.capitalization)
            .autocorrectionDisabled(!kind.allowsAutocorrect)
            .font(.system(size: bodySize, weight: .semibold))
            .foregroundColor(.white)
            .accessibilityLabel(label)
            .accessibilityHint(errorMessage ?? "")
            .accessibilityIdentifier(fieldID)
    }

    /// A real secure text field (UITextField.isSecureTextEntry), not an imitation:
    /// iOS masks it, VoiceOver does not read the characters, copy is disabled,
    /// Password AutoFill works, and XCUITest/Appium see a SecureTextField.
    private var secureInput: some View {
        KSecureInput(
            text: $text,
            placeholder: placeholder,
            isRevealed: isRevealed,
            accessibilityLabel: label,
            identifier: fieldID,
            focusRequest: focusRequest ?? Binding.constant(false),
            onReturn: onReturn
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var revealToggleButton: some View {
        // 44x44pt is Apple's minimum touch target. The label stays constant and
        // the state is exposed as a value, so automation can find it reliably.
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(KTheme.textMuted)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show password")
        .accessibilityValue(isRevealed ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
        .accessibilityIdentifier(fieldID + "_visibility_toggle")
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(errorMessage == nil ? KTheme.border : KTheme.danger.opacity(0.6), lineWidth: 1)
    }

    @ViewBuilder
    private var errorText: some View {
        if let errorMessage {
            Text(errorMessage)
                .font(.system(size: errorSize, weight: .semibold))
                .foregroundColor(KTheme.danger)
                .padding(.leading, 4)
                .accessibilityIdentifier(fieldID + "_error")
        }
    }

    private func applyFilter(_ newValue: String) {
        var cleaned = kind.sanitize(newValue)
        if let maxLength, cleaned.count > maxLength {
            cleaned = String(cleaned.prefix(maxLength))
        }
        if cleaned != newValue {
            text = cleaned
        }
    }
}

// MARK: - Secure text entry

struct KSecureInput: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isRevealed: Bool
    var accessibilityLabel: String
    var identifier: String
    @Binding var focusRequest: Bool
    var onReturn: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)

        // Explicit colors: SwiftUI's SecureField let the masked dots fall back to
        // a dark default, invisible on this app's near-black fields. UITextField
        // applies textColor to the dots directly.
        field.textColor = .white
        field.tintColor = .white
        field.keyboardAppearance = .dark
        field.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: UIFont.systemFont(ofSize: 15, weight: .semibold))
        field.adjustsFontForContentSizeCategory = true
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.5)]
        )

        // Password-field behavior: no capitalization/correction/suggestions,
        // password content type so Password AutoFill and strong passwords work.
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        field.keyboardType = .default
        field.textContentType = .password
        field.returnKeyType = .go
        field.clearButtonMode = .never
        field.isSecureTextEntry = !isRevealed

        field.accessibilityLabel = accessibilityLabel
        field.accessibilityIdentifier = identifier

        // Let SwiftUI size the field to the available width.
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self

        if field.text != text {
            field.text = text
        }

        let wantsSecure = !isRevealed
        if field.isSecureTextEntry != wantsSecure {
            // Toggling secure entry on a field that already has text makes UIKit
            // discard the existing text on the next keystroke. Re-assigning the
            // text after the toggle keeps it.
            let existing = field.text
            field.isSecureTextEntry = wantsSecure
            field.text = ""
            field.text = existing
        }

        if focusRequest {
            DispatchQueue.main.async {
                field.becomeFirstResponder()
                focusRequest = false
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KSecureInput

        init(_ parent: KSecureInput) {
            self.parent = parent
        }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn?()
            textField.resignFirstResponder()
            return false
        }
    }
}

// MARK: - Picker

struct KPicker<T: Hashable>: View {
    var label: String
    @Binding var selection: T
    var options: [(T, String)]
    /// Stable accessibility identifier. Defaults to one derived from `label`.
    var identifier: String? = nil

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 15
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 10

    private var selectedTitle: String {
        options.first(where: { $0.0 == selection })?.1 ?? "Select…"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: labelSize, weight: .black))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(KTheme.textMuted)
                .padding(.leading, 4)
                .accessibilityHidden(true)

            Menu {
                Picker(selection: $selection, label: EmptyView()) {
                    ForEach(options, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
            } label: {
                pickerLabel
            }
            .accessibilityLabel(label)
            .accessibilityValue(selectedTitle)
            .accessibilityIdentifier(identifier ?? label.kIdentifier)
        }
    }

    private var pickerLabel: some View {
        HStack {
            Text(selectedTitle)
                .font(.system(size: bodySize, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(KTheme.textMuted)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(16)
        .background(KTheme.bgBase)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(KTheme.border, lineWidth: 1))
    }
}

// MARK: - Spinner (mirrors components/common/Spinner.tsx)

struct KSpinner: View {
    var tint: Color = KTheme.emerald
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 48, height: 48)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
    }
}

// MARK: - Card container

struct KCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .background(KTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.border, lineWidth: 1))
    }
}

// MARK: - Progress bar used across multi-step flows

struct KStepProgressBar: View {
    var progress: Double
    var tint: Color = KTheme.emerald

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.06))
                Rectangle().fill(tint).frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 4)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .animation(.easeInOut(duration: 0.4), value: progress)
    }
}

func currency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return "$" + (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))
}
