// UI-IOS-19c · REQ-082 · REQ-060 — 직원 · 변경 계약서 받음 (하위 화면, 탭 바 없음)
// 서명 화면 · 계약서 전문은 호출하는 쪽 몫 — 클로저만 부른다.
import SwiftUI

struct WageChangeContractView: View {
    let state: WageChangeContractState
    var onBack: () -> Void
    var onOpenFull: () -> Void
    var onSign: () -> Void
    /// 서명 처리 중 — 호출하는 쪽 값. 처리 중에는 「서명하기」에만 표시하고 다시 누를 수 없다.
    let isSigning: Bool

    @Environment(\.dynamicTypeSize) private var typeSize

    /// 회색 원 아바타 지름(원문 약 26)
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 26

    init(state: WageChangeContractState,
         onBack: @escaping () -> Void = {},
         onOpenFull: @escaping () -> Void = {},
         onSign: @escaping () -> Void = {},
         isSigning: Bool = false) {
        self.state = state
        self.isSigning = isSigning
        self.onBack = onBack
        self.onOpenFull = onOpenFull
        self.onSign = onSign
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    wageSection
                    restCard
                    impactCard
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
                    Text(WageChangeContractState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(WageChangeContractState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { needsDecision; sent }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) { needsDecision; sent }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.sentSpoken))
            Text(WageChangeContractState.headerTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            sender
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var needsDecision: some View { PumBadge(text: WageChangeContractState.needsDecisionTitle, kind: .attention) }

    private var sent: some View {
        Text(state.sentText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var sender: some View {
        HStack(spacing: PumTokens.Space.s12) {
            if !state.senderInitial.isEmpty {
            Text(state.senderInitial)
                .font(PumFont.font(size: avatarSize * 0.42, weight: .bold, relativeTo: .caption))
                .foregroundStyle(PumTokens.ColorToken.gray800)
                .frame(width: avatarSize, height: avatarSize)
                .background(PumTokens.ColorToken.gray200, in: Circle())
                .accessibilityHidden(true)
            }
            Text(state.senderText).pumText(.callout, weight: .regular)
                .foregroundStyle(PumTokens.ColorToken.gray800)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.senderText))
    }

    // MARK: 시급

    private var wageSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            Text(state.wageHeading).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { currentTile; newTile }
                VStack(spacing: PumTokens.Space.s8) { currentTile; newTile }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.wageTilesSpoken))
        }
    }

    private var currentTile: some View {
        tile(label: WageChangeContractState.nowLabel, value: state.currentWageText, isNew: false)
    }

    private var newTile: some View {
        tile(label: state.newLabel, value: state.newWageText, isNew: true)
    }

    @ViewBuilder private func tile(label: String, value: String, isNew: Bool) -> some View {
        let r = PumTokens.Radius.lg
        let content = VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(label).pumText(.caption)
                .foregroundStyle(isNew ? PumColor.accent : PumColor.textSecondary)
            Text(value).pumText(.headline, weight: .bold)
                .strikethrough(!isNew)
                .foregroundStyle(isNew ? PumColor.textPrimary : PumColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isNew ? PumColor.accentSoft : PumColor.surfaceCard,
                    in: RoundedRectangle(cornerRadius: r, style: .continuous))
        if isNew {
            content
        } else {
            content.pumRing(.hairline, cornerRadius: r)
        }
    }

    // MARK: 카드

    private var restCard: some View {
        PumCard {
            cardTitle(WageChangeContractState.restHeading)
            pairRow(label: state.workRowTitle, value: state.workRowValue)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.workRowSpoken))
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            pairRow(label: state.payDayTitle, value: state.payDayValue)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.payDaySpoken))
        }
    }

    private var impactCard: some View {
        PumCard {
            cardTitle(WageChangeContractState.impactHeading)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) { impactLabel; Spacer(minLength: 0); impactValue }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { impactLabel; impactValue }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.impactSpoken))
        }
    }

    private var impactLabel: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(WageChangeContractState.impactTitle).pumText(.callout, weight: .regular)
                .foregroundStyle(PumTokens.ColorToken.gray800)
            Text(state.impactBasisText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var impactValue: some View {
        Text(state.impactDifferenceText).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.top, PumTokens.Size.rowPadY + PumTokens.Space.s2)
            .padding(.bottom, PumTokens.Space.s2)
            .accessibilityAddTraits(.isHeader)
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
        let full = PumButton(title: WageChangeContractState.fullTitle, kind: .outline, action: onOpenFull)
        let sign = PumButton(title: WageChangeContractState.signTitle, isLoading: isSigning, action: onSign)
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { sign; full }
        } else {
            RatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { full; sign } // 원문 약 1 : 1.5
        }
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 17g와 같은 값 — 공통 후보(충돌표 기타).
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

#Preview("19c 원문") { WageChangeContractView(state: .sample) }
#Preview("19c XXXL") { WageChangeContractView(state: .sample).dynamicTypeSize(.accessibility3) }
