// UI-IOS-2k · REQ-043 — 직원 · 추가 근무 요청 받음 (하위 화면, 탭 바 없음)
// 3a 요청 카드와 같은 요청의 상세. 수락 · 거절 버튼은 공통 PumButtonPair(.outline 먹색 테두리).
import SwiftUI

struct ExtraShiftOfferView: View {
    @State private var state: ExtraShiftOfferState
    var onBack: () -> Void
    /// 수락 — 끝나면 done(성공 여부). 실패면 잠금이 풀린다. 연결 전 기본값은 미전송(done(false))
    var onAccept: (@escaping (Bool) -> Void) -> Void
    /// 거절 — 위와 같음
    var onDecline: (@escaping (Bool) -> Void) -> Void

    init(state: ExtraShiftOfferState,
         onBack: @escaping () -> Void = {},
         onAccept: @escaping (@escaping (Bool) -> Void) -> Void = { done in done(false) },
         onDecline: @escaping (@escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onAccept = onAccept
        self.onDecline = onDecline
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: ExtraShiftOfferState.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    titleBlock
                    detailCard
                    weekCard
                    Text(state.noticeText)
                        .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16) // 머리 줄–제목 16(원문 gap)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // 처리 중에는 눌러도 반응하지 않는다(모양은 그대로 — 두 번 보내지 않기)
            PumButtonPair(negative: ExtraShiftOfferState.declineTitle, positive: ExtraShiftOfferState.acceptTitle,
                          negativeKind: .outline, onNegative: { respond(onDecline) }, onPositive: { respond(onAccept) })
                .allowsHitTesting(!state.isResponding)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12)
                .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 = 홈 막대 34 + 10
                .background(PumColor.bgApp)
        }
    }

    private func respond(_ action: (@escaping (Bool) -> Void) -> Void) {
        guard state.beginRespond() else { return }
        // 실패면 다시 누를 수 있게 풀고, 성공이면 잠근 채 둔다(호출한 쪽이 화면을 닫음)
        action { ok in if !ok { state.endRespond() } }
    }

    // MARK: 제목

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) { // 원문 메타–제목 6
            Text(state.metaText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(state.headline).pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: 요청 상세 카드

    private var detailCard: some View {
        PumCard {
            row("날짜") {
                HStack(spacing: 0) {
                    Text(state.dateText + (state.holidayName == nil ? "" : " · "))
                        .pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    if let holiday = state.holidayName {
                        Text(holiday).pumText(.body, weight: .semibold).foregroundStyle(PumColor.statusDanger)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.dateAccessibilityText))
            }
            divider
            row("시간") {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
                    Text(state.timeText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    if let breakText = state.breakText {
                        Text("· \(breakText)").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                }
            }
            divider
            row("사유") {
                Text(state.reason).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            }
            divider
            row("예상 급여") {
                VStack(alignment: .trailing, spacing: PumTokens.Space.s2) {
                    Text(state.expectedPayText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.statusDone)
                    HStack(spacing: 0) {
                        Text(state.payBasisText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        if let premium = state.premiumText {
                            Text(premium).pumText(.caption, weight: .bold).foregroundStyle(PumColor.statusDone)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.payAccessibilityText))
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Space.s18)
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func row<V: View>(_ label: String, @ViewBuilder value: () -> V) -> some View {
        let l = Text(label).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY + PumTokens.Space.s2)
        .padding(.horizontal, PumTokens.Space.s18) // 원문 padding 14 18
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    // MARK: 그 주 내 근무

    // 공통 후보: 홈 1at WeekStripCard와 모양이 달라(시간 표시 · 파랑 칸) 화면 전용으로 둔다.
    private var weekCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                Text(ExtraShiftOfferState.weekCardTitle).pumText(.footnote, weight: .bold)
                    .foregroundStyle(PumColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 0) {
                    ForEach(state.week) { WeekCell(day: $0) }
                }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                Text(state.weekSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, PumTokens.Space.s16) // 원문 padding 14 16
            .padding(.vertical, PumTokens.Space.s14)
        }
    }
}

private struct WeekCell: View {
    let day: ExtraShiftOfferDay

    var body: some View {
        let isRequest = day.kind == .thisRequest
        VStack(spacing: PumTokens.Space.s4) {
            Text(day.labelText).pumText(.caption2, weight: isRequest ? .bold : .regular)
                .foregroundStyle(isRequest ? PumColor.accent : PumColor.textTertiary)
            Text(day.valueText).pumText(.caption, weight: valueWeight).foregroundStyle(valueColor)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5) // 7칸 한 줄 유지 — 큰 글자에서 넘치면 줄인다
        .frame(maxWidth: .infinity)
        .padding(.vertical, PumTokens.Space.s2) // 원문 padding 2 0 · margin -2 0
        .background(isRequest ? PumColor.accentSoft : .clear,
                    in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
        .padding(.vertical, -PumTokens.Space.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.accessibilityText))
    }

    private var valueWeight: Font.Weight {
        switch day.kind { case .off: .regular; case .worked: .semibold; case .thisRequest: .bold }
    }

    private var valueColor: Color {
        switch day.kind {
        case .off: PumColor.textDisabled
        case .worked: PumColor.textPrimary
        case .thisRequest: PumColor.accent
        }
    }
}

#Preview("2k 원문") { ExtraShiftOfferView(state: .sample) }
#Preview("2k XXXL") { ExtraShiftOfferView(state: .sample).dynamicTypeSize(.accessibility3) }
