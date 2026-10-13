// UI-IOS-1ad · REQ-044 · DEC-005 — 급여 확정 전 근무기록 확인 요청(사장님). 같은 급여 화면 위 시트.
// 막을 눌러도 닫힌다(처리 중엔 잠금). 실제 전송 · 날짜 선택 화면은 후속(클로저).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
enum RecordReviewRequestViewLocal {
    /// 회신 막대 높이 — 원문 8
    static let barHeight: CGFloat = PumTokens.Space.s8
    /// 월 알약 높이 — 원문 padding 8 + 글자 16(누름 44 유지)
    static let monthPillHeight: CGFloat = PumTokens.Space.s8 * 2 + PumTokens.Space.s16
}

struct RecordReviewRequestView: View {
    @State private var state: RecordReviewRequestState
    @State private var sheetOpen: Bool
    /// 보내기 — 기한 · 자동 보내기 · 메시지가 담긴 상태를 넘긴다
    var onSend: (RecordReviewRequestState) -> Void
    var onPickDate: () -> Void
    var onClose: () -> Void

    @ScaledMetric(relativeTo: .footnote) private var barHeight = RecordReviewRequestViewLocal.barHeight

    init(state: RecordReviewRequestState = .sample, sheetOpen: Bool = true,
         onSend: @escaping (RecordReviewRequestState) -> Void = { _ in },
         onPickDate: @escaping () -> Void = {},
         onClose: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        _sheetOpen = State(initialValue: sheetOpen)
        self.onSend = onSend
        self.onPickDate = onPickDate
        self.onClose = onClose
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            // 처리 중에는 막 · VoiceOver 닫기로도 닫히지 않는다
            .pumBottomSheet(isPresented: sheetBinding, onDismiss: { if !state.isSending { onClose() } }) {
                RecordReviewRequestSheet(
                    state: $state,
                    onSend: {
                        // 누르는 즉시 처리 중으로 바꿔 두 번 보내지 않는다
                        guard state.beginSend() else { return }
                        onSend(state)
                    },
                    onPickDate: onPickDate)
            }
    }

    private var sheetBinding: Binding<Bool> {
        Binding(get: { sheetOpen }, set: { if !state.isSending { sheetOpen = $0 } })
    }

    /// 뒤 화면(시트에 덮여 어둡게): 머리 + 직원 확인 현황 카드
    private var background: some View {
        VStack(spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
            HStack {
                Text("급여").pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: PumTokens.Space.s8)
                Text(state.monthTitle).pumText(.callout, weight: .semibold) // 14px 600
                    .foregroundStyle(PumColor.textPrimary)
                    .padding(.horizontal, PumTokens.Space.s14)
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .background(PumColor.surfaceCard, in: Capsule())
                    .pumRing(.hairline, cornerRadius: PumTokens.Radius.pill)
                    .padding(.vertical, -(PumTokens.Size.tapMin - RecordReviewRequestViewLocal.monthPillHeight) / 2)
            }
            statusCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s12) // 위 여백 없음(원문 머리 줄이 안전 영역 바로 아래)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var statusCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        statusTitle
                        Spacer(minLength: PumTokens.Space.s8)
                        deadline
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        statusTitle
                        deadline
                    }
                }
                HStack(spacing: PumTokens.Space.s10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(PumColor.surfaceFill)
                            Capsule().fill(PumColor.statusDone)
                                .frame(width: geo.size.width * CGFloat(state.progressFraction))
                        }
                    }
                    .frame(height: barHeight)
                    Text(state.progressText).pumText(.footnote, weight: .bold) // 13px 700
                        .monospacedDigit().foregroundStyle(PumColor.textPrimary)
                }
                RecordReviewRequestFlow(spacing: PumTokens.Space.s6) {
                    ForEach(state.people) { p in
                        PumBadge(text: p.chipText, kind: badgeKind(p.reply))
                    }
                }
            }
            .padding(.horizontal, PumTokens.Space.s18) // 원문 padding 16 18
            .padding(.vertical, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.statusAccessibilityLabel))
        }
    }

    private var statusTitle: some View {
        Text(RecordReviewRequestState.statusTitle).pumText(.callout, weight: .bold) // 14px 700
            .foregroundStyle(PumColor.textPrimary)
    }

    private var deadline: some View {
        Text(state.replyDeadlineText).pumText(.caption, weight: .regular) // 12px
            .foregroundStyle(PumColor.textSecondary)
    }

    private func badgeKind(_ r: RecordReviewReplyPerson.Reply) -> PumBadge.Kind {
        switch r {
        case .ok: .done
        case .editRequested: .attention
        case .pending: .waiting
        }
    }
}

#Preview("1ad") { RecordReviewRequestView() }
#Preview("1ad · 큰 글자") { RecordReviewRequestView().dynamicTypeSize(.accessibility2) }
#Preview("1ad · 처리 중") {
    var s = RecordReviewRequestState.sample
    s.isSending = true
    return RecordReviewRequestView(state: s)
}
