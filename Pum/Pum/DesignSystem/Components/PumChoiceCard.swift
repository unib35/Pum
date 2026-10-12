// 카드형 선택(라디오) — 흰 카드 · 오른쪽 위 라디오 · 선택이면 파랑 2pt 테두리. 2c에서 옮겼다(2c · 5e).
// 내용(제목 · 설명 · 태그)은 화면이 넘긴다. 테두리 2 · 안쪽 18은 목업 실측(DEC-005).
import SwiftUI

enum PumChoiceCardStyle {
    /// 선택 테두리 두께(목업 2) — 토큰 밖 이름 상수
    static let selectedRing: CGFloat = 2
    /// 카드 안쪽 여백(목업 약 18)
    static let padding = PumTokens.Space.s18
}

struct PumChoiceCard<Content: View>: View {
    let isOn: Bool
    /// VoiceOver — 제목 · 설명을 카드 하나로 읽는다
    let accessibilityLabel: String
    /// 「3개 중 1번째」처럼 위치(선택 여부는 .isSelected 특성이 읽어 준다)
    var accessibilityValue: String = ""
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        let r = PumTokens.Radius.lg
        Button(action: action) {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                content.frame(maxWidth: .infinity, alignment: .leading)
                PumRadioMark(isOn: isOn)
            }
            .padding(PumChoiceCardStyle.padding)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay {
                if isOn {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(PumColor.accent, lineWidth: PumChoiceCardStyle.selectedRing)
                } else {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(PumColor.borderHairline, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}
