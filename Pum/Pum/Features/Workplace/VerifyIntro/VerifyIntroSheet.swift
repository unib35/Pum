// UI-IOS-5b · REQ-010 — 인증 시트 내용. 시트 판 · 막 · 모션 · 큰 글자 스크롤은 공통 C9(`pumBottomSheet`).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
enum VerifyIntroLocal {
    /// 단계 원 지름(원문 28)
    static let stepCircle: CGFloat = 28
    /// 뒤 화면 QR 자리 네모(원문 168)
    static let qrBox: CGFloat = 168
}

struct VerifyIntroSheet: View {
    let state: VerifyIntroState
    var onStart: () -> Void = {}
    var onLater: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                Text(VerifyIntroState.sheetTitle).pumText(.title3) // 원문 22px 700 → title3(1ad와 같은 결정)
                    .foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(VerifyIntroState.sheetBody).pumText(.footnote, weight: .regular) // 13px
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Space.s4)
            PumCard {
                VStack(spacing: 0) {
                    ForEach(Array(state.steps.enumerated()), id: \.element.id) { index, step in
                        if index > 0 { divider }
                        VerifyIntroStepRow(number: index + 1, step: step)
                    }
                }
            }
            VStack(spacing: PumTokens.Space.s4) {
                PumButton(title: VerifyIntroState.startTitle, kind: .primary, action: onStart)
                PumButton(title: VerifyIntroState.laterTitle, kind: .text, size: .small, action: onLater)
            }
            .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s8)
    }

    private var divider: some View {
        Rectangle().fill(PumTokens.ColorToken.borderHairline).frame(height: 1)
    }
}

/// 한 단계 행 — 원 표시 + 제목 + 부제. 공통에 같은 원 표시가 없어 화면 전용(공통 후보: 단계 원 표시).
/// 완료 = 초록 채움 + 흰 체크는 README 색 규칙(체크리스트 완료 = 회색 원)과 다르다 —
/// 인증 진행 단계라 원문(초록)대로, 충돌 #35.
struct VerifyIntroStepRow: View {
    let number: Int
    let step: VerifyIntroStep

    @ScaledMetric(relativeTo: .body) private var circle = VerifyIntroLocal.stepCircle

    var body: some View {
        HStack(alignment: .top, spacing: PumTokens.Space.s12) {
            marker
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(step.title).pumText(.body, weight: .semibold) // 15px 600
                    .foregroundStyle(PumColor.textPrimary)
                Text(step.subtitle).pumText(.caption, weight: .regular) // 12px
                    .foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s16) // 원문 행 높이 약 62
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.accessibilityLabel(number: number)))
        .accessibilityValue(Text(step.subtitle))
    }

    private var marker: some View {
        ZStack {
            Circle().fill(fill)
            switch step.status {
            case .done:
                Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(Color.white)
            case .current:
                Text("\(number)").pumText(.footnote, weight: .bold).foregroundStyle(Color.white) // 13px 700
            case .upcoming:
                Text("\(number)").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
            }
        }
        .frame(width: circle, height: circle)
    }

    private var fill: Color {
        switch step.status {
        case .done: PumColor.statusDone
        case .current: PumColor.textPrimary
        case .upcoming: PumColor.surfaceFill
        }
    }
}
