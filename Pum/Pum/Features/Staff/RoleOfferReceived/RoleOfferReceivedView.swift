// UI-IOS-17i · 17k · REQ-014 — 관리자 초대 받음 / 대표 권한 이전 요청 받음 (하위 화면, 탭 바 없음)
// 본인인증 화면 · 거절 확인 창은 원문이 없어 클로저만 부른다(호출하는 쪽 몫).
import SwiftUI

struct RoleOfferReceivedView: View {
    @State private var state: RoleOfferReceivedState
    var onBack: () -> Void
    /// 거절 — 끝나면 done(성공 여부). 실패면 잠금이 풀린다. 연결 전 기본값은 미전송(done(false))
    var onDecline: (@escaping (Bool) -> Void) -> Void
    /// 본인인증 후 수락 — 위와 같음
    var onAcceptWithVerification: (@escaping (Bool) -> Void) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    /// 회색 원 지름 — 6t와 같은 값(원문 약 26)
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    private let markRatio: CGFloat = 0.45

    init(state: RoleOfferReceivedState,
         onBack: @escaping () -> Void = {},
         onDecline: @escaping (@escaping (Bool) -> Void) -> Void = { done in done(false) },
         onAcceptWithVerification: @escaping (@escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onDecline = onDecline
        self.onAcceptWithVerification = onAcceptWithVerification
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    ForEach(Array(state.sections.enumerated()), id: \.offset) { _, section in
                        sectionCard(section)
                    }
                    if !state.pairs.isEmpty { pairsCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private func respond(_ button: RoleOfferResponse, _ action: (@escaping (Bool) -> Void) -> Void) {
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
                    Text(RoleOfferReceivedState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(RoleOfferReceivedState.backTitle))
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
            Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { verified; business }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) { verified; business }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.verifiedReadout))
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var needsDecision: some View { PumBadge(text: RoleOfferReceivedState.needsDecisionTitle, kind: .attention) }
    private var verified: some View { PumBadge(text: RoleOfferReceivedState.verifiedBadge, kind: .done) }

    private var sent: some View {
        Text(state.sentText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var business: some View {
        Text(state.businessText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 권한 카드

    private func sectionCard(_ section: RoleOfferSection) -> some View {
        PumCard {
            Text(section.title).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Size.rowPadY + PumTokens.Space.s2)
                .padding(.bottom, PumTokens.Space.s2)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(section.rows.enumerated()), id: \.offset) { index, row in
                if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                permissionRow(row, allowed: section.allowed)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(section.spoken(row)))
            }
        }
    }

    private func permissionRow(_ text: String, allowed: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            Circle().fill(PumColor.surfaceFill)
                .overlay {
                    Image(systemName: allowed ? "checkmark" : "xmark")
                        .font(.system(size: circleSize * markRatio, weight: .bold))
                        .foregroundStyle(allowed ? PumColor.textPrimary : PumColor.textTertiary)
                }
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
            Text(text).pumText(.callout, weight: .semibold)
                .foregroundStyle(allowed ? PumColor.textPrimary : PumColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    // MARK: 라벨-값 카드

    private var pairsCard: some View {
        PumCard {
            ForEach(Array(state.pairs.enumerated()), id: \.offset) { index, pair in
                if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                pairRow(pair)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(pair.spoken))
            }
        }
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func pairRow(_ pair: RoleOfferPair) -> some View {
        let l = Text(pair.label).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
        let v = Text(pair.value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
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
            Text(state.footerNotice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    @ViewBuilder private var buttons: some View {
        let decline = PumButton(title: RoleOfferReceivedState.declineTitle, kind: .outline,
                                isLoading: state.isLoading(.decline)) { respond(.decline, onDecline) }
        let accept = PumButton(title: RoleOfferReceivedState.acceptTitle,
                               isLoading: state.isLoading(.accept)) { respond(.accept, onAcceptWithVerification) }
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { accept; decline }
        } else {
            RoleOfferPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { decline; accept }
        }
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 한쪽이 다른 쪽에 밀려 찌그러지지 않는다.
private struct RoleOfferPairLayout: Layout {
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

#Preview("17i 원문") { RoleOfferReceivedView(state: .managerInvite) }
#Preview("17k 원문") { RoleOfferReceivedView(state: .ownerTransfer) }
#Preview("17i XXXL") { RoleOfferReceivedView(state: .managerInvite).dynamicTypeSize(.accessibility3) }
