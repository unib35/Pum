// UI-IOS-1j · REQ-042 — 내 스케줄(목록) + 대타 요청 시트
// 달력 보기 전환 · 실제 요청 취소 전송은 후속 — 액션 클로저로만 넘긴다.
import SwiftUI

struct MyScheduleView: View {
    var state: MyScheduleState = .sample
    var mode: MyScheduleMode = .list
    var onChangeMode: (MyScheduleMode) -> Void = { _ in }
    var onSelectItem: (ScheduleItem) -> Void = { _ in }
    var onCancelSubstitute: () -> Void = {}
    var onDismissSheet: () -> Void = {}

    @State private var tab = "work"
    @State private var sheetOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: MyScheduleState = .sample, mode: MyScheduleMode = .list, sheetOpen: Bool = true,
         onChangeMode: @escaping (MyScheduleMode) -> Void = { _ in },
         onSelectItem: @escaping (ScheduleItem) -> Void = { _ in },
         onCancelSubstitute: @escaping () -> Void = {},
         onDismissSheet: @escaping () -> Void = {}) {
        self.state = state
        self.mode = mode
        self.onChangeMode = onChangeMode
        self.onSelectItem = onSelectItem
        self.onCancelSubstitute = onCancelSubstitute
        self.onDismissSheet = onDismissSheet
        _sheetOpen = State(initialValue: sheetOpen)
    }

    // 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 날짜 칸 고정 폭(요일 + 숫자)
        static let dateColumnWidth: CGFloat = 40
        /// 대타 요청 중 행 강조 테두리 약 2pt
        static let highlightStroke: CGFloat = 2
    }

    var body: some View {
        listScreen
            .pumBottomSheet(isPresented: sheetBinding, onDismiss: onDismissSheet) {
                if let request = state.substitute {
                    SubstituteRequestSheet(request: request, onCancelRequest: onCancelSubstitute)
                }
            }
    }

    /// 대타 요청이 있을 때만 시트를 연다
    private var sheetBinding: Binding<Bool> {
        Binding(get: { sheetOpen && state.substitute != nil }, set: { sheetOpen = $0 })
    }

    // MARK: 뒤 화면(목록)

    private var listScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                header
                ForEach(state.sections) { section in
                    Text(section.title).pumText(.footnote, weight: .bold) // 목업 13px 700
                        .foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .padding(.top, PumTokens.Space.s8)
                        .accessibilityAddTraits(.isHeader)
                    sectionCard(section)
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                title
                Spacer(minLength: PumTokens.Space.s8)
                segment
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                segment
            }
        }
        .padding(.top, PumTokens.Space.s8)
    }

    private var title: some View {
        // 목업 28px 700 → title1(28)
        Text("내 스케줄").pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    /// 목록 · 달력 세그먼트: 회색 캡슐 바탕, 선택 칸은 흰 캡슐(M2)
    private var segment: some View {
        HStack(spacing: 0) {
            ForEach(MyScheduleMode.allCases, id: \.self) { m in
                let selected = m == mode
                Button { onChangeMode(m) } label: {
                    // 목업 13px 선택 600 먹색 / 500 보조색 → footnote
                    Text(m.title).pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s16)
                        .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                        .background(selected ? PumColor.surfaceCard : .clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: Capsule())
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: mode)
    }

    // MARK: 섹션 카드 · 행

    private func sectionCard(_ section: ScheduleSection) -> some View {
        PumCard {
            ForEach(Array(section.items.enumerated()), id: \.element.id) { i, item in
                row(item, isLast: i == section.items.count - 1)
            }
        }
    }

    @ViewBuilder private func row(_ item: ScheduleItem, isLast: Bool) -> some View {
        let content = rowContent(item, isLast: isLast)
        if item.showsChevron || item.isSubstituteRequested {
            Button { select(item) } label: { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.accessibilityLabel))
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.accessibilityLabel))
        }
    }

    private func select(_ item: ScheduleItem) {
        if item.isSubstituteRequested, state.substitute != nil { sheetOpen = true }
        onSelectItem(item)
    }

    private func rowContent(_ item: ScheduleItem, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            dateColumn(item)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                timeLine(item)
                Text(item.subtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let badge = item.badge {
                PumBadge(text: badge.text, kind: badge.kind)
            }
            if item.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
        .overlay {
            if item.isSubstituteRequested {
                // 대타 요청 중: 주황 테두리 약 2pt(statusAttention)
                RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous)
                    .strokeBorder(PumColor.statusAttention, lineWidth: Local.highlightStroke)
                    .allowsHitTesting(false)
            }
        }
    }

    private func dateColumn(_ item: ScheduleItem) -> some View {
        VStack(spacing: PumTokens.Space.s2) {
            if item.isToday {
                // 목업 11px 700 파랑 → caption2 bold, accent
                Text(ScheduleItem.todayText).pumText(.caption2, weight: .bold).foregroundStyle(PumColor.accent)
            } else {
                Text(item.weekday).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            // 목업 17px 700 → headline(17) bold
            Text("\(item.day)").pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
        .frame(minWidth: Local.dateColumnWidth)
    }

    private func timeLine(_ item: ScheduleItem) -> some View {
        // 목업 15px 600 → body(16) semibold
        let time = Text(item.timeRange).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        // 목업 11px 700 주황(amber400 = statusAttentionDot)
        let changed = Text(ScheduleItem.changedText).pumText(.caption2, weight: .bold)
            .foregroundStyle(PumColor.statusAttentionDot)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s6) {
                time
                if item.isChanged { changed }
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                time
                if item.isChanged { changed }
            }
        }
    }
}

#Preview("1j") { MyScheduleView() }
#Preview("1j · 시트 닫힘") { MyScheduleView(sheetOpen: false) }
#Preview("1j · 큰 글자") { MyScheduleView().dynamicTypeSize(.xxxLarge) }
