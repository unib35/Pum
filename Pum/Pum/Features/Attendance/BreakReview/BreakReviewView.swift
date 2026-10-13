// UI-IOS-19i · REQ-030 — 사장님 · 휴게 못 씀 확인 (하위 화면, 탭 바 없음)
// 「다른 시간으로」 화면은 호출하는 쪽 몫 — 클로저만 부른다.
import SwiftUI

struct BreakReviewView: View {
    let state: BreakReviewState
    var onBack: () -> Void
    var onOtherTime: () -> Void
    /// 인정 — 처리가 끝나면 done(성공 여부)을 부른다. 성공하면 잠근 채 둔다.
    var onApprove: (_ done: @escaping (Bool) -> Void) -> Void

    @State private var isApproving = false
    @State private var isApproved = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var statusCircle = PumLayout.avatar - PumTokens.Space.s12

    init(state: BreakReviewState,
         onBack: @escaping () -> Void = {},
         onOtherTime: @escaping () -> Void = {},
         onApprove: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { $0(true) }) {
        self.state = state
        self.onBack = onBack
        self.onOtherTime = onOtherTime
        self.onApprove = onApprove
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    breakTiles
                    reasonCard
                    ifApprovedCard
                    if let title = state.repeatTitle, let law = state.repeatWarning?.lawText {
                        repeatCard(title: title, law: law)
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(BreakReviewState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(BreakReviewState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { badge; sender }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) { badge; sender }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.sentSpoken))
            Text(BreakReviewState.headerTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(state.shiftText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var badge: some View { PumBadge(text: BreakReviewState.needsCheckTitle, kind: .attention) }

    private var sender: some View {
        Text(state.senderText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 휴게 비교

    private var breakTiles: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { plannedTile; actualTile }
            VStack(spacing: PumTokens.Space.s8) { plannedTile; actualTile }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.breakTilesSpoken))
    }

    private var plannedTile: some View {
        tile(label: BreakReviewState.plannedLabel, value: state.plannedText, isActual: false)
    }

    private var actualTile: some View {
        tile(label: BreakReviewState.actualLabel, value: state.actualText, isActual: true)
    }

    @ViewBuilder private func tile(label: String, value: String, isActual: Bool) -> some View {
        let r = PumTokens.Radius.lg
        let content = VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(label).pumText(.caption)
                .foregroundStyle(isActual ? PumColor.accent : PumColor.textSecondary)
            Text(value).pumText(.headline, weight: .bold)
                .strikethrough(!isActual)
                .foregroundStyle(isActual ? PumColor.textPrimary : PumColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActual ? PumColor.accentSoft : PumColor.surfaceCard,
                    in: RoundedRectangle(cornerRadius: r, style: .continuous))
        if isActual {
            content
        } else {
            content.pumRing(.hairline, cornerRadius: r)
        }
    }

    // MARK: 카드

    private var reasonCard: some View {
        PumCard {
            pairRow(label: BreakReviewState.reasonLabel, value: state.reasonText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.reasonSpoken))
    }

    private var ifApprovedCard: some View {
        PumCard {
            Text(BreakReviewState.ifApprovedTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Size.rowPadY + PumTokens.Space.s2)
                .padding(.bottom, PumTokens.Space.s2)
                .accessibilityAddTraits(.isHeader)
            pairRow(label: BreakReviewState.workedLabel, value: state.workedChangeText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.workedSpoken))
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) { costLabel; Spacer(minLength: 0); costValue }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { costLabel; costValue }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.costSpoken))
        }
    }

    private var costLabel: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(BreakReviewState.costLabel).pumText(.callout, weight: .regular)
                .foregroundStyle(PumTokens.ColorToken.gray800)
            Text(state.costBasisText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var costValue: some View {
        Text(state.costText).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func pairRow(label: String, value: String) -> some View {
        let l = Text(label).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
        let v = Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY + PumTokens.Space.s2)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private func repeatCard(title: String, law: String) -> some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                Text("!").pumText(.callout, weight: .heavy) // 원문 15px 800
                    .foregroundStyle(PumColor.statusAttention)
                    .frame(width: statusCircle, height: statusCircle)
                    .background(PumColor.statusAttentionSoft, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(law).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.repeatSpoken ?? ""))
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            buttons
            Text(state.footerNotice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    @ViewBuilder private var buttons: some View {
        let other = PumButton(title: BreakReviewState.otherTimeTitle, kind: .outline, action: onOtherTime)
            .disabled(isApproving) // 처리 중에는 다른 길로 가지 않게 — 모양 변화는 이 버튼만
        let approve = PumButton(title: BreakReviewState.approveTitle, isLoading: isApproving, action: approveTapped)
        Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: PumTokens.Space.s8) { approve; other }
            } else {
                RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { other; approve } // 원문 약 1 : 1.5
            }
        }
        .disabled(isApproved)
    }

    private func approveTapped() {
        guard !isApproving, !isApproved else { return }
        isApproving = true
        onApprove { ok in
            isApproving = false
            if ok { isApproved = true }
        }
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 19c와 같은 값 — 공통 후보.
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

#Preview("19i 원문") { BreakReviewView(state: .sample) }
#Preview("19i 경고 없음") { BreakReviewView(state: .sampleNoWarning) }
#Preview("19i XXXL") { BreakReviewView(state: .sample).dynamicTypeSize(.accessibility3) }
