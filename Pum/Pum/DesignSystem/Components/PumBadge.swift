// C2 Status Badge — 글자만(아이콘 · 점 없음) · 12px 600 · 모서리 8 · 안쪽 여백 4/9
import SwiftUI

struct PumBadge: View {
    /// 상태 시스템 6가지. 배경은 디자인의 다섯 가지 연한 색.
    enum Kind: CaseIterable {
        case waiting      // 대기
        case active       // 진행 · 행동
        case done         // 완료 · 확정
        case attention    // 확인 필요
        case problem      // 문제 · 거절
        case closed       // 종료 · 취소
    }

    let text: String
    var kind: Kind = .waiting

    var body: some View {
        Text(text)
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .semibold, relativeTo: .caption))
            .monospacedDigit()
            .foregroundStyle(colors.fg)
            .padding(.vertical, PumTokens.Space.s4)
            .padding(.horizontal, 9)
            .background(colors.bg, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            .overlay {
                if kind == .closed { // 종료 · 취소: 흰 바탕 + 테두리
                    RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                        .strokeBorder(PumTokens.ColorToken.gray300, lineWidth: 1)
                }
            }
            .accessibilityLabel(Text("상태: \(text)"))
    }

    var colors: (fg: Color, bg: Color) {
        switch kind {
        case .waiting: (PumColor.textSecondary, PumColor.surfaceFill)
        case .active: (PumColor.accent, PumColor.accentSoft)
        case .done: (PumColor.statusDone, PumColor.statusDoneSoft)
        case .attention: (PumColor.statusAttention, PumColor.statusAttentionSoft)
        case .problem: (PumColor.statusDanger, PumColor.statusDangerSoft)
        case .closed: (PumColor.textSecondary, PumColor.surfaceCard)
        }
    }
}
