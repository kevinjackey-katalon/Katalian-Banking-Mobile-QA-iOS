import SwiftUI

// MARK: - Button variants (mirrors components/common/Button.tsx)

enum KButtonVariant { case primary, secondary, ghost, danger }

struct KButton: View {
    var title: String
    var variant: KButtonVariant = .primary
    var fullWidth: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
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

// MARK: - Input field (mirrors components/common/Input.tsx)

struct KTextField: View {
    var label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(KTheme.textMuted)
                .padding(.leading, 4)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(16)
            .background(KTheme.bgBase)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(errorMessage == nil ? KTheme.border : KTheme.danger.opacity(0.6), lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(KTheme.danger)
                    .padding(.leading, 4)
            }
        }
    }
}

struct KPicker<T: Hashable>: View {
    var label: String
    @Binding var selection: T
    var options: [(T, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(KTheme.textMuted)
                .padding(.leading, 4)

            Menu {
                Picker(selection: $selection, label: EmptyView()) {
                    ForEach(options, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
            } label: {
                HStack {
                    Text(options.first(where: { $0.0 == selection })?.1 ?? "Select…")
                        .font(.system(size: 15, weight: .semibold))
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
