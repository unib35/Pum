// 선택 부품 — 라디오 행(1ao · 1al 사유) · 체크박스 행(1z 동의)
// 화면마다 따로 있던 같은 모양을 모았다. 원 22 · 점 0.36 · 테두리 1.5는 목업 실측(토큰 밖 크기라 이름 상수, DEC-005).
import SwiftUI

enum PumSelectionStyle {
    /// 라디오 원 · 체크 네모 한 변(목업 약 22) — 큰 글자에서 글자와 함께 커진다
    static let markSize: CGFloat = 22
    /// 선택된 라디오 가운데 흰 점 지름 비율
    static let dotRatio: CGFloat = 0.36
    /// 선택 안 된 라디오 테두리 두께
    static let ringWidth: CGFloat = 1.5
}

/// 라디오 표시(원). 선택 = 파랑 채움 + 흰 점, 선택 안 됨 = gray300 테두리
struct PumRadioMark: View {
    let isOn: Bool
    @ScaledMetric private var size = PumSelectionStyle.markSize

    var body: some View {
        ZStack {
            if isOn {
                Circle().fill(PumColor.accent)
                Circle().fill(.white).frame(width: size * PumSelectionStyle.dotRatio)
            } else {
                Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: PumSelectionStyle.ringWidth)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// 라디오 행 — 원 + 문구. 선택 행은 600 먹색, 나머지 400 gray800(1ao · 1al 원문). 카드 안 행 여백 · 44 터치.
/// VoiceOver: 「문구, N개 중 M번째」 + 선택 특성(라벨에 「선택됨」을 넣지 않는다 — 두 번 읽힘)
struct PumRadioRow: View {
    let title: String
    let isOn: Bool
    let index: Int
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                Text(title)
                    .pumText(.callout, weight: isOn ? .semibold : .regular)
                    .foregroundStyle(isOn ? PumColor.textPrimary : PumTokens.ColorToken.gray800)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title), \(count)개 중 \(index + 1)번째"))
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// 체크 표시(둥근 네모). 선택 = 파랑 채움 + 흰 체크, 선택 안 됨 = 흰 바탕 + hairline(원문에 없는 상태 — 추정)
struct PumCheckMark: View {
    let isOn: Bool
    @ScaledMetric(relativeTo: .footnote) private var size = PumSelectionStyle.markSize

    var body: some View {
        RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
            .fill(isOn ? PumColor.accent : PumColor.surfaceCard)
            .overlay {
                if isOn {
                    Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(.white)
                } else {
                    RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                        .strokeBorder(PumColor.borderHairline, lineWidth: 1)
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// 체크박스 행 — 네모 + 여러 줄 문구. 행 전체 누름 · 44 터치.
/// VoiceOver: 문구 전체를 라벨로(무엇에 동의하는지가 핵심), 값 「선택됨/선택 안 됨」, 토글 특성
struct PumCheckboxRow: View {
    let title: String
    let isOn: Bool
    var textColor: Color = PumColor.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: PumTokens.Space.s10) {
                PumCheckMark(isOn: isOn)
                Text(title).pumText(.footnote).foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Space.s4)
            .padding(.vertical, PumTokens.Space.s10)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isOn ? "선택됨" : "선택 안 됨"))
        .accessibilityAddTraits(.isToggle)
    }
}
