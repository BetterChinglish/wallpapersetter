import SwiftUI

// MARK: - Type Badge (Video / HTML)

struct TypeBadge: View {
    let type: WallpaperType

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(type == .video ? Color.appBadgeVideoText : Color.appBadgeWebText)
                .frame(width: 6, height: 6)

            Text(type == .video ? "视频" : "网页")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(type == .video ? Color.appBadgeVideoText : Color.appBadgeWebText)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(type == .video ? Color.appBadgeVideo : Color.appBadgeWeb)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        TypeBadge(type: .video)
        TypeBadge(type: .html)
    }
    .padding()
}
