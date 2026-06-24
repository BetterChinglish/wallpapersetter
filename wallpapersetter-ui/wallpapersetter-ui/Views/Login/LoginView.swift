import SwiftUI

// MARK: - Login View (WeChat QR Code)

struct LoginView: View {
    @Environment(AppViewModel.self) private var vm

    @State private var qrCodeData: QRCodeData?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Blurred backdrop
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 64)

                // App Icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appAccent)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.appAccent.opacity(0.25), radius: 12, y: 4)

                Spacer().frame(height: 20)

                // App Name
                Text("Wallpaper Setter")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Spacer().frame(height: 4)

                Text("让桌面鲜活起来")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextMuted)

                Spacer().frame(height: 32)

                // QR Code Area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .frame(width: 176, height: 176)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)

                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else if let error = errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.appTextMuted)
                            Button("重试") {
                                Task { await loadQRCode() }
                            }
                            .font(.system(size: 12))
                        }
                        .frame(width: 140)
                    } else if qrCodeData != nil {
                        // QR code visual placeholder
                        VStack(spacing: 8) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 80))
                                .foregroundColor(.appTextPrimary)

                            Text("微信扫码")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.appTextPlaceholder)
                        }
                    } else {
                        Text("加载中...")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextPlaceholder)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appCardStroke, lineWidth: 1)
                )

                Spacer().frame(height: 20)

                Text("请使用微信扫描二维码登录")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextMuted)

                Spacer().frame(height: 36)

                // Cancel Button
                MutedButton(title: "取消") {
                    vm.authService.stopPolling()
                    vm.showLogin = false
                }

                Spacer().frame(height: 12)

                // Help Link
                Button("首次使用？查看帮助") {
                    // Open help URL
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.appTextMuted.opacity(0.7))
            }
        }
        .frame(width: 440, height: 560)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, y: 2)
        )
        .task {
            await loadQRCode()
        }
    }

    private func loadQRCode() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await vm.authService.generateQRCode()
            qrCodeData = data
            isLoading = false

            // Start polling
            vm.authService.startPolling(sceneId: data.sceneId) {
                vm.showLogin = false
            }
        } catch {
            errorMessage = "加载失败"
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(AppViewModel())
}
