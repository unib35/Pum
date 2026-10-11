// 개인 모드 표시(REQ-006 PERSONAL) — 점선 윤곽 · 점선 「내 기록」 태그. 2f에서 옮겼다(2f · 2g · 2h).
// 점선은 gray400(맞는 의미 토큰 없음), 간격은 간격 토큰. 태그 안쪽 가로 9는 PumBadge와 같은 값.
import SwiftUI

/// 점선 윤곽 — 본인이 입력 · 자유 수정하는 것(사업장 확인 전)
struct PumDashedOutline: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(PumTokens.ColorToken.gray400,
                              style: StrokeStyle(lineWidth: 1, dash: [PumTokens.Space.s4, PumTokens.Space.s2]))
        }
    }
}

extension View {
    func pumDashedOutline(cornerRadius: CGFloat) -> some View { modifier(PumDashedOutline(radius: cornerRadius)) }
}

/// 점선 「내 기록」 태그 — 본인이 입력한 기록(REQ-006)
struct PumMyRecordTag: View {
    var body: some View {
        Text("내 기록")
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .semibold, relativeTo: .caption))
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .padding(.vertical, PumTokens.Space.s4)
            .padding(.horizontal, 9) // PumBadge와 같은 안쪽 여백
            .pumDashedOutline(cornerRadius: PumTokens.Radius.sm)
    }
}
