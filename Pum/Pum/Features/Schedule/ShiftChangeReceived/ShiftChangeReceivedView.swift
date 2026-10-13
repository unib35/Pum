// UI-IOS-17f · REQ-050 — 직원 · 게시 후 근무 변경 요청 받음 (하위 화면, 탭 바 없음)
// 기존 → 변경 · 급여 영향 · 응답 전까지 기존 근무. 거절 사유 입력 · 확인 창은 원문이 없어 클로저만 부른다(결정 필요).
import SwiftUI

struct ShiftChangeReceivedView: View {
    @State private var state: ShiftChangeReceivedState
    var onBack: () -> Void
    /// 수락 — 끝나면 done(성공 여부). 실패면 잠금이 풀린다. 연결 전 기본값은 미전송(done(false))
    var onAccept: (@escaping (Bool) -> Void) -> Void
    /// 거절 — 위와 같음
    var onDecline: (@escaping (Bool) -> Void) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    init(state: ShiftChangeReceivedState,
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
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    Text(state.dateText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                        .padding(.horizontal, PumTokens.Space.s4)
                    timesPair
                    reasonCard
                    impactCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private func respond(_ button: ShiftChangeResponse, _ action: (@escaping (Bool) -> Void) -> Void) {
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
                    Text(ShiftChangeReceivedState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(ShiftChangeReceivedState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            HStack(spacing: PumTokens.Space.s8) {
                PumBadge(text: ShiftChangeReceivedState.needsDecisionTitle, kind: .attention)
                Text(state.sentAtText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            }
            Text(ShiftChangeReceivedState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: PumTokens.Space.s10) {
                Text(state.senderInitial)
                    .pumText(.caption2, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .frame(width: senderSize, height: senderSize)
                    .background(PumColor.surfaceFill, in: Circle())
                    .accessibilityHidden(true)
                Text(state.senderText).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    /// 디자인 28pt 원 — 토큰 조합
    private var senderSize: CGFloat { PumTokens.Space.s24 + PumTokens.Space.s4 }

    // MARK: 기존 · 변경

    private var timesPair: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { beforeCell; afterCell }
            VStack(spacing: PumTokens.Space.s8) { beforeCell; afterCell }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.timesAccessibilityText))
    }

    private var beforeCell: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(ShiftChangeReceivedState.beforeLabel).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            Text(state.beforeTimeText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textTertiary)
                .strikethrough()
        }
        .lineLimit(1)
        .fixedSize()
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var afterCell: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(ShiftChangeReceivedState.afterLabel).pumText(.caption).foregroundStyle(PumColor.accent)
            Text(state.afterTimeText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
        .lineLimit(1)
        .fixedSize()
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.accentSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 카드

    private var reasonCard: some View {
        PumCard {
            row(ShiftChangeReceivedState.reasonLabel, state.reason)
        }
    }

    private var impactCard: some View {
        PumCard {
            Text(ShiftChangeReceivedState.impactTitle).pumText(.body, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Size.rowPadY + PumTokens.Space.s2)
                .padding(.bottom, PumTokens.Space.s2)
                .accessibilityAddTraits(.isHeader)
            row(ShiftChangeReceivedState.creditedLabel, state.creditedText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.creditedAccessibilityText))
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            row(ShiftChangeReceivedState.payLabel, state.payDeltaText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.payAccessibilityText))
        }
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func row(_ label: String, _ value: String) -> some View {
        let l = Text(label).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let v = Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY + PumTokens.Space.s2)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            buttons
                // 처리 중에는 눌러도 반응하지 않는다(모양은 그대로 — 두 번 보내지 않기)
                .allowsHitTesting(!state.isResponding)
            Text(ShiftChangeReceivedState.footerNotice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    @ViewBuilder private var buttons: some View {
        let decline = PumButton(title: ShiftChangeReceivedState.declineTitle, kind: .outline,
                                isLoading: state.isLoading(.decline)) { respond(.decline, onDecline) }
        let accept = PumButton(title: ShiftChangeReceivedState.acceptTitle,
                               isLoading: state.isLoading(.accept)) { respond(.accept, onAccept) }
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { accept; decline }
        } else {
            RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { decline; accept }
        }
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 한쪽이 다른 쪽에 밀려 찌그러지지 않는다.
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

#Preview("17f 원문") { ShiftChangeReceivedView(state: .sample) }
#Preview("17f XXXL") { ShiftChangeReceivedView(state: .sample).dynamicTypeSize(.accessibility3) }
