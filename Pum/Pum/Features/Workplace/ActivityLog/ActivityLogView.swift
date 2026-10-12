// UI-IOS-6l · REQ-091 — 활동 기록(사장님, 탭 바 없음). 행은 누르지 않고 수정 · 삭제 동작도 없다.
// 검색어만 화면 상태. 거르기는 서버 몫이라 바뀌면 onSearch로 알리고, 받은 목록을 그대로 보여준다.
import SwiftUI

struct ActivityLogView: View {
    var state: ActivityLogState = .sample
    var onBack: () -> Void = {}
    /// 내보내기 — 화면은 파일을 만들지 않는다
    var onExport: () -> Void = {}
    var onSearch: (String) -> Void = { _ in }
    var onPickDropdown: (String) -> Void = { _ in }
    var onToggleQuickFilter: (String) -> Void = { _ in }

    @State private var query = ""
    @Environment(\.dynamicTypeSize) private var typeSize
    /// 시각 열 폭(목업 약 40) — 글자 크기를 따라 커짐
    @ScaledMetric(relativeTo: .caption) private var timeWidth: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "활동 기록", onBack: onBack) {
                PumIconButton(systemImage: "arrow.down.to.line", label: "활동 기록 내보내기", action: onExport)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)

            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    searchField
                    ActivityLogFlow(hSpacing: PumTokens.Space.s8, vSpacing: PumTokens.Space.s8) {
                        ForEach(state.dropdowns) { dropdownChip($0) }
                    }
                    ActivityLogFlow(hSpacing: PumTokens.Space.s8, vSpacing: PumTokens.Space.s8) {
                        ForEach(state.quickFilters) { quickChip($0) }
                    }
                    ForEach(state.days) { day in
                        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                            PumSectionHeader(title: day.title)
                            PumCard {
                                ForEach(Array(day.entries.enumerated()), id: \.element.id) { i, e in
                                    row(e, isLast: i == day.entries.count - 1)
                                }
                            }
                        }
                    }
                    Text(state.footerNote)
                        .pumText(.caption, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    // MARK: 검색

    private var searchField: some View {
        HStack(spacing: PumTokens.Space.s10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: PumLayout.navIcon, weight: .regular))
                .foregroundStyle(PumColor.textSecondary)
                .accessibilityHidden(true)
            TextField("", text: $query, prompt: Text(state.searchPlaceholder).foregroundStyle(PumColor.textTertiary))
                .pumText(.body, weight: .regular)
                .foregroundStyle(PumColor.textPrimary)
                .submitLabel(.search)
                .onSubmit { onSearch(query) } // 한글 조합 중 글자마다 서버로 보내지 않게 「검색」을 누를 때만
                .accessibilityLabel(Text(state.searchPlaceholder))
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(minHeight: PumTokens.Size.tapMin)
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .pumRing(.hairline, cornerRadius: PumTokens.Radius.lg)
    }

    // MARK: 칩

    private func dropdownChip(_ d: ActivityDropdown) -> some View {
        Button { onPickDropdown(d.id) } label: {
            HStack(spacing: PumTokens.Space.s6) {
                Text(d.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Space.s14)
            .padding(.vertical, PumTokens.Space.s6)
            .background(PumColor.surfaceCard, in: Capsule())
            .pumRing(.hairline, cornerRadius: PumTokens.Radius.pill)
            .contentShape(Rectangle().inset(by: -PumTokens.Space.s8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(d.title))
        .accessibilityHint(Text("바꿔요"))
    }

    private func quickChip(_ f: ActivityQuickFilter) -> some View {
        Button { onToggleQuickFilter(f.id) } label: {
            Text(f.title)
                .pumText(.caption, weight: .semibold)
                .foregroundStyle(f.isOn ? PumColor.accent : PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s10)
                .padding(.vertical, PumTokens.Space.s6)
                .background(f.isOn ? PumColor.accentSoft : PumColor.surfaceFill,
                            in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(f.title))
        .accessibilityAddTraits(f.isOn ? [.isSelected] : [])
    }

    // MARK: 기록 행

    private func row(_ e: ActivityEntry, isLast: Bool) -> some View {
        let big = typeSize.isAccessibilitySize
        // 큰 글자: 시각 열이 넘치지 않게 시각을 내용 위로 올린다
        let outer = big
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s4))
            : AnyLayout(HStackLayout(alignment: .top, spacing: PumTokens.Space.s12))
        return outer {
            Text(e.timeText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary)
                .frame(width: big ? nil : timeWidth, alignment: .leading)
            HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(e.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(e.actorText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PumBadge(text: e.kind.label, kind: badgeKind(e.kind))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(e.accessibilityText))
    }

    private func badgeKind(_ k: ActivityKind) -> PumBadge.Kind {
        switch k {
        case .payroll: .done
        case .work: .waiting
        case .contract: .active
        }
    }
}

/// 칩 줄바꿈 배치 — 받은 폭을 그대로 돌려준다(칩이 모자라도 부모 폭 유지)
private struct ActivityLogFlow: Layout {
    var hSpacing: CGFloat
    var vSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let a = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: proposal.width ?? a.width, height: a.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (i, p) in arrange(width: bounds.width, subviews: subviews).origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (width: CGFloat, height: CGFloat, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + vSpacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + hSpacing
            maxX = max(maxX, x - hSpacing)
            rowH = max(rowH, sz.height)
        }
        return (maxX, y + rowH, origins)
    }
}

#Preview("6l") { ActivityLogView() }
#Preview("6l · 큰 글자") { ActivityLogView().dynamicTypeSize(.accessibility2) }
#Preview("6l · XXXL") { ActivityLogView().dynamicTypeSize(.xxxLarge) }
