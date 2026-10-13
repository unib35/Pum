// UI-IOS-10k · REQ-042 — 사장님 휴무·변경 요청 처리. 탭 바 없음.
// 색: 주황 = 처리 필요(「필요 3명」). 인건비 증가 · 야간 가산은 경고처럼 강조하지 않는다(REQ-051) — 원문 색 그대로.
// 승인 · 거절 후 카드가 사라지는 것은 서버 새 상태(state)로 다시 그리는 것이다.
import SwiftUI

struct RequestInboxView: View {
    var state: RequestInboxState = .sample
    var onBack: () -> Void = {}
    /// 「승인」 · 「거절」. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onDecide: (_ requestId: String, _ decision: RequestDecision, _ done: @escaping (Bool) -> Void) -> Void = { _, _, done in done(false) }

    @State private var lock = RequestRowLock()
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack) { EmptyView() }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(spacing: PumTokens.Space.s12) {
                    ForEach(state.items) { card($0) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: state) { old, new in lock.refresh(old: old.items, new: new.items) } // 바뀐 카드만 잠금 해제
    }

    private func card(_ item: RequestItem) -> some View {
        let locked = lock.isLocked(item.id)
        return PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                    head(item)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(item.titleText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                        Text(item.detailText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    impactBox(item)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.accessibilityHeader))
                .accessibilityValue(Text("\(item.titleText). \(item.detailText). \(item.accessibilityImpacts)"))
                buttons(item, locked: locked)
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.vertical, PumTokens.Space.s14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func head(_ item: RequestItem) -> some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s10) {
            PumAvatar(name: item.name, colorIndex: item.colorIndex)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s10) { who(item); Spacer(minLength: PumTokens.Space.s8); time(item) }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    HStack(spacing: PumTokens.Space.s10) { who(item) }
                    time(item)
                }
            }
        }
    }

    private func who(_ item: RequestItem) -> some View {
        Group {
            Text(item.name).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            PumBadge(text: item.kindText, kind: .waiting)
        }
    }

    private func time(_ item: RequestItem) -> some View {
        Text(item.relativeTime).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary)
    }

    // MARK: 영향 상자

    private func impactBox(_ item: RequestItem) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(item.impacts.enumerated()), id: \.element.id) { i, row in
                if i > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                impactRow(row)
            }
        }
        .padding(.horizontal, PumTokens.Space.s12)
        .padding(.vertical, PumTokens.Space.s4)
        .background(PumColor.bgApp, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
    }

    private func impactRow(_ row: RequestImpactRow) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                label(row)
                Spacer(minLength: PumTokens.Space.s8)
                value(row)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { // 큰 글자는 세로
                label(row)
                value(row)
            }
        }
        .padding(.vertical, PumTokens.Space.s8) // 누르는 행이 아니라 최소 높이 44를 두지 않는다
    }

    private func label(_ row: RequestImpactRow) -> some View {
        Text(row.label).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func value(_ row: RequestImpactRow) -> some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text(row.value).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            // 서버가 부족 표시를 줄 때만 — 원문 12px 600 주황 알약 = 공통 PumBadge(.attention)
            if let s = row.shortageText { PumBadge(text: s, kind: .attention) }
        }
    }

    // MARK: 버튼

    private func buttons(_ item: RequestItem, locked: Bool) -> some View {
        let pressed = lock.decision(item.id)
        // 카드 안 버튼 — 원문 약 42. 처리 중 표시는 누른 버튼에만, 다른 버튼은 잠금
        let reject = PumButton(title: item.rejectText, kind: .outline, size: .small, isLoading: pressed == .reject) { decide(item, .reject) }
            .disabled(locked)
            .accessibilityLabel(Text(item.rejectAccessibility))
        let approve = PumButton(title: item.approveText, kind: .primary, size: .small, isLoading: pressed == .approve) { decide(item, .approve) }
            .disabled(locked)
            .accessibilityLabel(Text(item.approveAccessibility))
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: PumTokens.Space.s10) { reject; approve } // 넘치면 세로 — 순서는 가로와 같게(거절 → 승인)
            } else {
                RequestButtonSplit(spacing: PumTokens.Space.s10) { reject; approve } // 원문 거절 : 승인 = 1 : 1.5
            }
        }
    }

    private func decide(_ item: RequestItem, _ decision: RequestDecision) {
        guard lock.begin(item.id, decision) else { return }
        onDecide(item.id, decision) { success in lock.finish(item.id, success: success) }
    }
}

/// 두 버튼을 1 : 1.5로 나눈다. 높이는 큰 쪽에 맞춘다 — 공통 후보(PumButtonPair는 처리 중 표시를 못 쓴다)
private struct RequestButtonSplit: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        let sizes = zip(subviews, widths(w)).map { $0.sizeThatFits(.init(width: $1, height: nil)) }
        return CGSize(width: w, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (view, w) in zip(subviews, widths(bounds.width)) {
            view.place(at: CGPoint(x: x, y: bounds.minY), proposal: .init(width: w, height: bounds.height))
            x += w + spacing
        }
    }

    private func widths(_ total: CGFloat) -> [CGFloat] {
        let unit = (total - spacing) / 2.5
        return [unit, unit * 1.5]
    }
}

#Preview("10k") { RequestInboxView(state: .sample) }
#Preview("10k XXXL") { RequestInboxView(state: .sample).dynamicTypeSize(.accessibility3) }
