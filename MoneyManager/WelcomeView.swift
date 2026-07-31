import SwiftUI

struct WelcomeView: View {
    var onFinish: () -> Void

    @AppStorage("userNickname") private var nickname: String = ""
    @State private var typedName: String = ""
    @FocusState private var fieldFocused: Bool

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showField = false
    @State private var showButton = false
    @State private var iconRotation: Double = -15
    @State private var iconScale: CGFloat = 0.4

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .opacity(showIcon ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Selamat Datang")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 16)

                    Text("Yuk atur keuanganmu dengan lebih rapi.\nSiapa nama panggilanmu?")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 12)
                }
                .padding(.horizontal, 32)

                VStack(spacing: 14) {
                    TextField("Nama panggilan", text: $typedName)
                        .focused($fieldFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit(commit)

                    Button(action: commit) {
                        Text("Mulai")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(typedName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(typedName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 32)
                .opacity(showField ? 1 : 0)
                .offset(y: showField ? 0 : 20)

                Spacer()
                Spacer()
            }
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            showIcon = true
            iconScale = 1.0
            iconRotation = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.45)) { showTitle = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.65)) { showSubtitle = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            showField = true
            showButton = true
        }
    }

    private func commit() {
        let trimmed = typedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        nickname = trimmed
        fieldFocused = false
        onFinish()
    }
}
