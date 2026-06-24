import SwiftUI

// MARK: - App Color System (Design Tokens)

extension Color {
    // Primary
    static let appAccent = Color(red: 0, green: 0.478, blue: 1.0)          // #007AFF
    static let appAccentLight = Color(red: 0.91, green: 0.94, blue: 1.0)   // #E8F0FE

    // Backgrounds
    static let appBackground = Color(red: 0.95, green: 0.95, blue: 0.97)   // #F2F2F7
    static let appContentBg = Color(red: 0.96, green: 0.96, blue: 0.97)     // #F5F5F7
    static let appSidebar = Color(red: 0.95, green: 0.95, blue: 0.97)       // #F2F2F7

    // Surfaces
    static let appCard = Color.white
    static let appCardStroke = Color(red: 0.90, green: 0.90, blue: 0.90)    // #E5E5E5

    // Text
    static let appTextPrimary = Color(red: 0.06, green: 0.09, blue: 0.16)   // #0F172A
    static let appTextSecondary = Color(red: 0.28, green: 0.28, blue: 0.29)  // #48484A
    static let appTextMuted = Color(red: 0.53, green: 0.53, blue: 0.55)      // #86868B
    static let appTextPlaceholder = Color(red: 0.81, green: 0.81, blue: 0.82) // #CECED2

    // Badge
    static let appBadgeVideo = Color(red: 0.91, green: 0.94, blue: 1.0)     // #E8F0FE
    static let appBadgeVideoText = Color.appAccent
    static let appBadgeWeb = Color(red: 0.90, green: 0.96, blue: 0.92)      // #E6F5EA
    static let appBadgeWebText = Color(red: 0.20, green: 0.78, blue: 0.35)  // #34C759

    // Toggle
    static let appToggleOn = Color.appAccent
    static let appToggleOff = Color(red: 0.90, green: 0.90, blue: 0.90)     // #E5E5E5

    // Traffic Lights
    static let trafficClose = Color(red: 1.0, green: 0.373, blue: 0.341)    // #FF5F57
    static let trafficMinimize = Color(red: 1.0, green: 0.741, blue: 0.18)   // #FFBD2E
    static let trafficMaximize = Color(red: 0.157, green: 0.792, blue: 0.255) // #28CA41

    // Button
    static let appBtnSecondaryBg = Color(red: 0.96, green: 0.96, blue: 0.97) // #F5F5F7
    static let appBtnSecondaryStroke = Color(red: 0.90, green: 0.90, blue: 0.90) // #E5E5E5

    // Divider
    static let appDivider = Color(red: 0.94, green: 0.94, blue: 0.96)       // #F0F0F5
}
