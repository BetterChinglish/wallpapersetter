import SwiftUI

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextPlaceholder)

            TextField("搜索壁纸...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.appTextPrimary)
                .onSubmit {
                    onSubmit?()
                }
        }
        .padding(.horizontal, 10)
        .frame(width: 280, height: 36)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appCardStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

// MARK: - Search Field Small

struct SearchFieldSmall: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.appTextMuted)

            TextField("搜索...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(Color.appBtnSecondaryBg)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.appCardStroke, lineWidth: 1)
        )
    }
}

// MARK: - Sort Menu

struct SortMenu: View {
    @Binding var selection: SortOption

    var body: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    HStack {
                        Text(option.label)
                        if selection == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selection.label)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.appTextMuted)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .frame(width: 100)
    }
}

extension SortOption {
    var label: String {
        switch self {
        case .newest: "最新"
        case .popular: "最热"
        case .liked: "最多赞"
        }
    }
}

// MARK: - Traffic Lights (Mac-style)

struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.trafficClose).frame(width: 12, height: 12)
            Circle().fill(Color.trafficMinimize).frame(width: 12, height: 12)
            Circle().fill(Color.trafficMaximize).frame(width: 12, height: 12)
        }
        .frame(width: 56)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SearchField(text: .constant(""))
        SearchFieldSmall(text: .constant(""))
        SortMenu(selection: .constant(.newest))
        TrafficLights()
    }
    .padding()
}
