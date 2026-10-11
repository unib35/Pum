// C11 Toast — 하단 · 3초 · 결과 알림만(결정은 토스트로 묻지 않음) · 먹색 바탕 · 모서리 12 · 여백 12/16 · float 그림자
// M4: --dur-base 등장 · --toast-hold 유지 · 동작 줄이기면 페이드만
import SwiftUI

struct PumToast: View {
    let message: String
    /// 앞 아이콘(선택): 완료 = checkmark(초록), 오프라인 = wifi.slash(주황)
    var systemImage: String?
    var iconColor: Color = PumTokens.ColorToken.green300
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: PumTokens.Space.s12) {
            if let systemImage {
                Image(systemName: systemImage).font(.footnote.weight(.bold)).foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }
            Text(message).pumText(.callout).foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .pumText(.callout)
                    .foregroundStyle(PumTokens.ColorToken.blue300)
                    .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Space.s16)
        .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .pumFloatShadow()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

extension View {
    /// 화면 아래에 토스트를 띄우고 3초 뒤 닫는다.
    func pumToast(_ message: Binding<String?>) -> some View {
        modifier(PumToastHost(message: message))
    }
}

private struct PumToastHost: ViewModifier {
    @Binding var message: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                PumToast(message: message)
                    .padding(.horizontal, PumTokens.Size.screenPad)
                    .padding(.bottom, PumTokens.Space.s16)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .task(id: message) {
                        AccessibilityNotification.Announcement(message).post()
                        try? await Task.sleep(for: .seconds(PumTokens.Duration.toastHold))
                        withAnimation(PumMotion.exit) { self.message = nil }
                    }
            }
        }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.base), value: message)
    }
}
