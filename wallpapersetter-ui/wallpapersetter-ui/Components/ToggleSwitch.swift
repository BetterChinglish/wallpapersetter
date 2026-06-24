import SwiftUI

// MARK: - Toggle Switch (iOS/macOS hybrid style)

struct ToggleSwitch: View {
    @Binding var isOn: Bool
    var isEnabled = true

    var body: some View {
        Button {
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.appToggleOn : Color.appToggleOff)
                    .frame(width: 40, height: 24)

                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(isOn ? 0.1 : 0.06), radius: 3, y: 1)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ToggleSwitch(isOn: .constant(true))
        ToggleSwitch(isOn: .constant(false))
        ToggleSwitch(isOn: .constant(true), isEnabled: false)
    }
    .padding()
}
