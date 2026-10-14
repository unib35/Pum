// UI-IOS-17g · REQ-042 — 직원 · 동료의 대타 요청 받음 (하위 화면, 탭 바 없음)
// 그 주 시간 · 예상 급여 · 사장님 승인 후 확정. 거절 사유 입력 · 확인 창은 원문이 없어 클로저만 부른다(결정 필요).
import SwiftUI

struct CoverRequestReceivedView: View {
    @State private var state: CoverRequestReceivedState
    var onBack: () -> Void
    /// 수락 — 끝나면 done(성공 여부). 실패면 잠금이 풀린다. 연결 전 기본값은 미전송(done(false))
    var onAccept: (@escaping (Bool) -> Void) -> Void
    /// 거절 — 위와 같음
    var onDecline: (@escaping (Bool) -> Void) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var badge = PumTokens.Space.s24 + PumTokens.Space.s2 // 원문 번호 원 약 26

    init(state: CoverRequestReceivedState,
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
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    header
                    shiftCard
                    impactCard
                    stepsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
                .padding(.bottom, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private func respond(_ button: CoverRequestResponse, _ action: (@escaping (Bool) -> Void) -> Void) {
        guard let next = state.beginning(button) else { return }
        state = next
        // 실패면 다시 누를 수 있게 풀고, 성공이면 잠근 채 둔다(호출한 쪽이 화면을 닫음)
        action { ok in if !ok { state = state.ended() } }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(CoverRequestReceivedState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s2) // DEC-010: 원문 머리 줄 40(누름 영역은 44 유지)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(CoverRequestReceivedState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var header: some View {
        // 원문: 배지 · 제목 묶음(padding 2 4 0, 제목 위 6) 다음 보낸 사람 줄이 블록 사이 14로 이어진다
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                HStack(spacing: PumTokens.Space.s8) {
                    PumBadge(text: CoverRequestReceivedState.needsDecisionTitle, kind: .attention)
                    Text(state.sentAtText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(CoverRequestReceivedState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.top, PumTokens.Space.s2)
            HStack(spacing: PumTokens.Space.s10) {
                Text(state.senderInitial)
                    .pumText(.caption2, weight: .bold).foregroundStyle(PumColor.accent)
                    .frame(width: senderSize, height: senderSize)
                    .background(PumColor.accentSoftStrong, in: Circle())
                    .accessibilityHidden(true)
                Text(state.senderText).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    /// 디자인 28pt 원 — 토큰 조합
    private var senderSize: CGFloat { PumTokens.Space.s24 + PumTokens.Space.s4 }

    // MARK: 근무 카드

    private var shiftCard: some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) { // 원문 gap 12
                VStack(spacing: 0) {
                    Text(state.weekdayText).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    Text(state.dayText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                }
                .fixedSize()
                .frame(minWidth: PumTokens.Size.tapMin)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(state.timeText).pumText(.headline, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.placeText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Size.rowPadY) // 원문 padding 11 16 → 가까운 12
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.shiftAccessibilityText))
    }

    // MARK: 수락하면

    private var impactCard: some View {
        PumCard {
            Text(CoverRequestReceivedState.ifAcceptTitle).pumText(.body, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Space.s14) // 원문 padding 14 16 4
                .padding(.bottom, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            impactRow(CoverRequestReceivedState.weekHoursLabel, state.weekHoursText, note: nil)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.weekHoursAccessibilityText))
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            impactRow(CoverRequestReceivedState.payLabel, state.payDeltaText, note: state.payNote)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.payAccessibilityText))
        }
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func impactRow(_ label: String, _ value: String, note: String?) -> some View {
        let l = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            if let note {
                Text(note).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        let v = Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                l.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                v.fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 padding 11 16 → 가까운 12
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 3단계

    private var stepsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ForEach(Array(state.steps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step, isLast: index == state.steps.count - 1)
                }
            }
        }
    }

    private func stepRow(_ step: CoverRequestStep, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            Text("\(step.number)")
                .pumText(.caption2, weight: .bold)
                .foregroundStyle(step.isDone ? PumColor.accent : PumColor.textSecondary)
                .frame(width: badge, height: badge)
                .overlay(Circle().strokeBorder(step.isDone ? PumColor.accent : PumColor.textDisabled,
                                               lineWidth: PumTokens.Space.s2))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(step.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                if let note = step.note {
                    Text(note).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.spoken))
    }

    // MARK: 하단

    private var footer: some View {
        buttons
            // 처리 중에는 눌러도 반응하지 않는다(모양은 그대로 — 두 번 보내지 않기)
            .allowsHitTesting(!state.isResponding)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s12) // 원문 padding 12 20 34 — 아래 34는 홈 표시 영역이 대신한다
            .background(PumColor.bgApp)
    }

    @ViewBuilder private var buttons: some View {
        let decline = PumButton(title: CoverRequestReceivedState.declineTitle, kind: .outlineLight,
                                isLoading: state.isLoading(.decline)) { respond(.decline, onDecline) }
        let accept = PumButton(title: CoverRequestReceivedState.acceptTitle,
                               isLoading: state.isLoading(.accept)) { respond(.accept, onAccept) }
            .disabled(!state.canAccept)
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { accept; decline }
        } else {
            RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { decline; accept }
        }
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸).
private struct RatioPairLayout: Layout {
    var ratio: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let widths = columnWidths(total: width)
        let height = zip(subviews, widths)
            .map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = columnWidths(total: bounds.width)
        var x = bounds.minX
        for (view, width) in zip(subviews, widths) {
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }

    private func columnWidths(total: CGFloat) -> [CGFloat] {
        let unit = max(0, total - spacing) / (1 + ratio)
        return [unit, unit * ratio]
    }
}

#Preview("17g 원문") { CoverRequestReceivedView(state: .sample) }
#Preview("17g XXXL") { CoverRequestReceivedView(state: .sample).dynamicTypeSize(.accessibility3) }
