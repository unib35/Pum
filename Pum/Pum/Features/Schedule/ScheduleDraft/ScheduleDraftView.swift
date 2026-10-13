// UI-IOS-17a · REQ-050 — 사장님 · 다음 주 초안(게시 전엔 직원에게 안 보임)
// 색: 파랑 = 다음 동작(근무 추가 · 게시), 빨강 = 일요일 · 공휴일 날짜, 회색 배지 = 초안 · 변경 · 추가.
// 숫자 · 문구는 서버 값 그대로. 버튼은 클로저만 받는다.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만 이름을 붙인다(DEC-005). 사용처에서 @ScaledMetric으로 키운다.
enum ScheduleDraftLayout {
    /// 근무 줄 시간 열 폭(목업 약 56)
    static let timeColumn: CGFloat = 56
    /// 근무 줄 아바타(목업 약 44 → 가까운 값 40)
    static let rowAvatar: CGFloat = 40
    /// 주간 스트립 칸 최소 폭(접근성 글자 크기에서 가로 스크롤할 때)
    static let stripCellMin: CGFloat = 56
}

struct ScheduleDraftView: View {
    private let state: ScheduleDraftState
    @State private var selectedID: Int
    @State private var isSheetOpen: Bool
    @State private var tab = "work"
    private let onChangeWorkplace: () -> Void
    private let onSelectDay: (Int) -> Void
    private let onAddShift: (DraftDay) -> Void
    private let onCopyLastWeek: () -> Void
    private let onPublish: () -> Void
    private let onDraftChange: (AddShiftDraft) -> Void
    private let onAddToDraft: (AddShiftDraft) -> Void
    private let onCancelPublish: () -> Void
    private let onConfirmPublish: () -> Void
    private let onSendChangeRequest: (String) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    init(state: ScheduleDraftState = .sample,
         onChangeWorkplace: @escaping () -> Void = {},
         onSelectDay: @escaping (Int) -> Void = { _ in },
         onAddShift: @escaping (DraftDay) -> Void = { _ in },
         onCopyLastWeek: @escaping () -> Void = {},
         onPublish: @escaping () -> Void = {},
         onDraftChange: @escaping (AddShiftDraft) -> Void = { _ in },
         onAddToDraft: @escaping (AddShiftDraft) -> Void = { _ in },
         onCancelPublish: @escaping () -> Void = {},
         onConfirmPublish: @escaping () -> Void = {},
         onSendChangeRequest: @escaping (String) -> Void = { _ in }) {
        self.state = state
        _selectedID = State(initialValue: state.selectedID)
        _isSheetOpen = State(initialValue: state.hasSheet)
        self.onChangeWorkplace = onChangeWorkplace
        self.onSelectDay = onSelectDay
        self.onAddShift = onAddShift
        self.onCopyLastWeek = onCopyLastWeek
        self.onPublish = onPublish
        self.onDraftChange = onDraftChange
        self.onAddToDraft = onAddToDraft
        self.onCancelPublish = onCancelPublish
        self.onConfirmPublish = onConfirmPublish
        self.onSendChangeRequest = onSendChangeRequest
    }

    var body: some View {
        content
            .pumBottomSheet(isPresented: $isSheetOpen) {
                if let sheet = state.sheet {
                    AddShiftSheet(state: sheet, onDraftChange: onDraftChange) { draft in
                        onAddToDraft(draft)
                        isSheetOpen = false
                    }
                } else if let publish = state.publishSheet {
                    PublishConfirmSheet(state: publish, onCancel: {
                        onCancelPublish()
                        isSheetOpen = false
                    }, onConfirm: onConfirmPublish)
                } else if let change = state.changeSheet {
                    PublishedChangeSheet(state: change, onSend: onSendChangeRequest)
                }
            }
            .onChange(of: state.selectedID) { _, new in selectedID = new }
            .onChange(of: state.hasSheet) { _, hasSheet in isSheetOpen = hasSheet }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: PumTokens.Space.s12) {
                    header
                    weekCard
                    dayLine
                    shiftsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.bottom, PumTokens.Space.s16)
            }
            if state.showsBottomBar { bottomBar }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: state.workTabBadge), selection: $tab)
        }
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                title
                Spacer(minLength: PumTokens.Space.s8)
                chip
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                chip
            }
        }
        .padding(.top, PumTokens.Space.s8)
    }

    private var title: some View {
        Text(ScheduleDraftState.title).pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
            .accessibilityAddTraits(.isHeader)
    }

    private var chip: some View {
        PumInverseWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial, action: onChangeWorkplace)
    }

    // MARK: 주간 카드

    private var weekCard: some View {
        PumCard {
            VStack(spacing: PumTokens.Space.s8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PumTokens.Space.s8) {
                        weekTitle
                        Spacer(minLength: PumTokens.Space.s8)
                        PumBadge(text: state.weekBadge.text, kind: state.weekBadge.kind)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        weekTitle
                        PumBadge(text: state.weekBadge.text, kind: state.weekBadge.kind)
                    }
                }
                DraftWeekStrip(days: state.days, selectedID: selectedID) { id in
                    withAnimation(PumMotion.respecting(reduceMotion, PumMotion.fast)) { selectedID = id } // M22
                    onSelectDay(id)
                }
            }
            .padding(PumTokens.Space.s12)
        }
    }

    private var weekTitle: some View {
        Text(state.weekTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 15px 700
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: 선택한 날 줄

    private var dayLine: some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text(state.selectedTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Button {
                // 시트는 서버가 시트 값(직원 · 계산)을 줄 때 연다 — 값 없이 열면 빈 시트가 올라온다
                if let day = state.days.first(where: { $0.id == selectedID }) { onAddShift(day) }
                if state.sheet != nil { isSheetOpen = true }
            } label: {
                Text(ScheduleDraftState.addShiftTitle).pumText(.footnote, weight: .semibold) // 13px 600
                    .foregroundStyle(PumColor.accent)
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var shiftsCard: some View {
        PumCard {
            ForEach(Array(state.shifts.enumerated()), id: \.element.id) { i, shift in
                if i > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                DraftShiftRow(shift: shift)
            }
        }
    }

    // MARK: 하단 — 지난주 복사 · 게시(받은 폭 2 : 3)

    private var bottomBar: some View {
        VStack(spacing: PumTokens.Space.s8) {
            if typeSize.isAccessibilitySize {
                VStack(spacing: PumTokens.Space.s8) { publishButton; copyButton }
            } else {
                DraftRatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { copyButton; publishButton }
            }
            Text(state.footnote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s12)
    }

    private var copyButton: some View {
        PumButton(title: ScheduleDraftState.copyLastWeekTitle, kind: .outline, action: onCopyLastWeek)
    }

    private var publishButton: some View {
        PumButton(title: ScheduleDraftState.publishTitle) {
            onPublish()
            // 게시 확인 시트도 서버가 값을 줄 때만 연다
            if state.publishSheet != nil { isSheetOpen = true }
        }
    }
}

// MARK: - 주간 스트립

private struct DraftWeekStrip: View {
    let days: [DraftDay]
    let selectedID: Int
    let onSelect: (Int) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric private var cellMin = ScheduleDraftLayout.stripCellMin

    var body: some View {
        // 접근성 글자 크기에서는 칸이 좁아져 글자가 잘리므로 가로 스크롤
        if typeSize.isAccessibilitySize {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PumTokens.Space.s4) {
                    ForEach(days) { cell($0).frame(minWidth: cellMin) }
                }
            }
        } else {
            HStack(spacing: PumTokens.Space.s4) {
                ForEach(days) { cell($0) }
            }
        }
    }

    private func cell(_ day: DraftDay) -> some View {
        let selected = day.id == selectedID
        return Button { onSelect(day.id) } label: {
            VStack(spacing: PumTokens.Space.s2) {
                Text(day.weekday).pumText(.caption2, weight: .regular)
                    .foregroundStyle(selected ? PumColor.textOnInverseSecondary : (day.isRed ? PumColor.statusDanger : PumColor.textSecondary))
                Text("\(day.id)").pumText(.headline, weight: selected ? .bold : .semibold) // 16px → headline(17), 1t와 같은 단계
                    .foregroundStyle(selected ? .white : (day.isRed ? PumColor.statusDanger : PumColor.textPrimary))
                Text(day.countText).pumText(.caption2, weight: .semibold) // 10px 600 → caption2(11)
                    .foregroundStyle(selected ? PumColor.accentOnInverse : PumColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PumTokens.Space.s8)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(selected ? PumColor.surfaceInverse : .clear,
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.accessibilityLabel()))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - 근무 한 줄

private struct DraftShiftRow: View {
    let shift: DraftShift
    @ScaledMetric private var timeColumn = ScheduleDraftLayout.timeColumn
    @ScaledMetric private var avatar = ScheduleDraftLayout.rowAvatar

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                main
                badge
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                main
                badge
            }
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(shift.accessibilityText))
    }

    private var main: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(shift.start).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary) // 14px 700
                Text(shift.end).pumText(.caption).foregroundStyle(PumColor.textTertiary)                  // 12px #8A919E
            }
            .frame(minWidth: timeColumn, alignment: .leading)
            PumAvatar(name: shift.name, colorIndex: shift.colorIndex, size: avatar)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(shift.name).pumText(.callout).foregroundStyle(PumColor.textPrimary)                  // 14px 600
                Text(shift.note).pumText(.caption).foregroundStyle(PumColor.textSecondary)                // 12px
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var badge: some View {
        if let text = shift.badgeText { PumBadge(text: text, kind: .waiting) }
    }
}

// MARK: - 두 칸 비율 배치(6u와 같은 방식)

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 한쪽이 다른 쪽에 밀려 찌그러지지 않는다.
struct DraftRatioPairLayout: Layout {
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

#Preview("17a") { ScheduleDraftView() }
#Preview("17b") { ScheduleDraftView(state: .addingShift) }
#Preview("17a · 큰 글자") { ScheduleDraftView().dynamicTypeSize(.xxxLarge) }
#Preview("17b · 큰 글자") { ScheduleDraftView(state: .addingShift).dynamicTypeSize(.xxxLarge) }
#Preview("17c") { ScheduleDraftView(state: .confirmingPublish) }
#Preview("17d") { ScheduleDraftView(state: .changingPublished) }
#Preview("17c · 큰 글자") { ScheduleDraftView(state: .confirmingPublish).dynamicTypeSize(.xxxLarge) }
#Preview("17d · 큰 글자") { ScheduleDraftView(state: .changingPublished).dynamicTypeSize(.xxxLarge) }
#Preview("17a · 접근성") { ScheduleDraftView().dynamicTypeSize(.accessibility2) }
