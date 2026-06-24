import SwiftUI

// MARK: - Primary Button (Filled blue)

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Color.appAccent.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

// MARK: - Secondary Button (Outlined)

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.appBtnSecondaryBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appBtnSecondaryStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

// MARK: - Muted Button (white/gray)

struct MutedButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextPrimary)
                .frame(width: 160, height: 40)
                .background(Color.appBtnSecondaryBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appBtnSecondaryStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "设为主屏幕壁纸", action: {})
        SecondaryButton(title: "设为所有屏幕壁纸", action: {})
        MutedButton(title: "取消", action: {})
    }
    .padding()
    .frame(width: 340)
}
