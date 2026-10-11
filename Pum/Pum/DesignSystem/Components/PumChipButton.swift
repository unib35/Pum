// C1 SMALL · 카드 안 연한 버튼 — 인정(파랑) · 처리(회색) · 퇴근 확인(주황). 12px 700 · 모서리 12
// 보이는 크기는 작고, 터치 영역은 44pt 이상.
import SwiftUI

struct PumChipButton: View {
    enum Kind: CaseIterable { case accent, neutral, attention }

    let title: String
    var kind: Kind = .neutral
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .pumText(.caption, weight: .bold)
                .foregroundStyle(colors.fg)
                .padding(.horizontal, PumTokens.Space.s14)
                .padding(.vertical, PumTokens.Space.s8)
                .background(colors.bg, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s8))
        }
        .buttonStyle(PumChipPressStyle())
    }

    var colors: (fg: Color, bg: Color) {
        switch kind {
        case .accent: (PumColor.accent, PumColor.accentSoft)
        case .neutral: (PumColor.textPrimary, PumColor.surfaceFill)
        case .attention: (PumColor.statusAttention, PumColor.statusAttentionSoft)
        }
    }
}

private struct PumChipPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1) // M1
            .animation(PumMotion.respecting(reduceMotion, PumMotion.press), value: configuration.isPressed)
    }
}
