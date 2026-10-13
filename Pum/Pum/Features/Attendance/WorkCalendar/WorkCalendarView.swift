// UI-IOS-1g · REQ-006 · REQ-107 — 근무 캘린더: 월 보기 + 월 요약
// 선택 · 월 이동 · 상세 이동은 모두 액션 클로저로 넘긴다(화면은 선택 상태를 들고 있지 않음).
import SwiftUI

struct WorkCalendarView: View {
    var state: WorkCalendarState = .sample
    var onWorkplace: () -> Void = {}
    var onPrevMonth: () -> Void = {}
    var onNextMonth: () -> Void = {}
    var onSelectDay: (Int) -> Void = { _ in }
    var onOpenDetail: () -> Void = {}
    var onOpenSchedule: () -> Void = {}
    @State private var tab = "work"

    @ViewBuilder var body: some View {
        if let empty = state.empty {
            emptyBody(empty)
        } else {
            recordsBody
        }
    }

    private var recordsBody: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s14) {
                header
                calendarCard
                selectedCard
                summaryCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    // MARK: 빈 상태(UI-IOS-6p · REQ-095) — 장식 없이 다음 행동만

    private func emptyBody(_ empty: WorkCalendarEmpty) -> some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                emptyCalendarCard(empty)
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    // 목업 20px 700 → title3(20)
                    Text(WorkCalendarEmpty.title).pumText(.title3).foregroundStyle(PumColor.textPrimary)
                    Text(WorkCalendarEmpty.hint).pumText(.callout, weight: .regular)
                        .foregroundStyle(PumColor.textSecondary)
                    Text("다음 근무는 \(Text(empty.nextWorkText).bold().foregroundStyle(PumColor.textPrimary))이에요.")
                        .pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Space.s8)
                .padding(.top, PumTokens.Space.s16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(empty.accessibilityText))
                PumButton(title: WorkCalendarEmpty.scheduleButton, kind: .outline, action: onOpenSchedule)
                    .padding(.top, PumTokens.Space.s8)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    /// 6p 달력 카드: 달 이동 · 범례 없이 제목 · 요일 · 날짜만
    private func emptyCalendarCard(_ empty: WorkCalendarEmpty) -> some View {
        let layout = state.layout
        return PumCard {
            VStack(spacing: PumTokens.Space.s8) {
                Text(state.monthTitle).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .frame(minHeight: PumTokens.Size.tapMin)
                quietWeekdayHeader
                VStack(spacing: 0) {
                    ForEach(0..<layout.weekCount, id: \.self) { week in
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(0..<WorkCalendarLayout.columns, id: \.self) { col in
                                emptyCell(layout, empty, slot: week * WorkCalendarLayout.columns + col)
                            }
                        }
                    }
                }
            }
            .padding(PumTokens.Space.s16)
        }
    }

    @ViewBuilder private func emptyCell(_ layout: WorkCalendarLayout, _ empty: WorkCalendarEmpty, slot: Int) -> some View {
        if let d = layout.day(atSlot: slot) {
            WorkCalendarDayCell(
                day: d, isSunday: layout.isSunday(d), isToday: false, mark: nil,
                label: empty.dayLabel(d), action: { onSelectDay(d) },
                isQuiet: true, showsPlannedDot: empty.plannedDays.contains(d))
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                .accessibilityHidden(true)
        }
    }

    // MARK: 머리

    private var header: some View {
        HStack {
            // 목업 28px 700 → title1(28)
            Text("근무").pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PumTokens.Space.s8)
            PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial, action: onWorkplace)
        }
    }

    // MARK: 달력

    private var calendarCard: some View {
        PumCard {
            // 원문: 카드 padding 14 12 10 · 달 줄 아래 10 · 요일 줄 아래 6 · 범례 위 10 아래 2
            VStack(spacing: 0) {
                monthBar
                    .padding(.horizontal, PumTokens.Space.s6)
                    .padding(.bottom, PumTokens.Space.s10)
                weekdayHeader
                    .padding(.bottom, PumTokens.Space.s6)
                grid
                legend
                    .padding(.top, PumTokens.Space.s10)
                    .padding(.bottom, PumTokens.Space.s2)
            }
            .padding(.top, PumTokens.Space.s14)
            .padding(.bottom, PumTokens.Space.s10)
            .padding(.horizontal, PumTokens.Space.s12)
        }
    }

    private var monthBar: some View {
        HStack {
            chevron("chevron.left", label: "이전 달", action: onPrevMonth)
            Spacer()
            // 목업 16px 700 → headline(17) bold
            Text(state.monthTitle).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            chevron("chevron.right", label: "다음 달", action: onNextMonth)
        }
    }

    /// 원형이 아닌 단순 chevron, 터치 44pt
    private func chevron(_ name: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.callout.weight(.semibold))
                .foregroundStyle(PumColor.textSecondary)
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
                // 원문 아이콘 8x14 — 누름 영역 44는 유지하고 배치만 줄인다
                .padding(.vertical, -(PumTokens.Size.tapMin - PumTokens.Space.s14) / 2)
                .padding(.horizontal, -(PumTokens.Size.tapMin - PumTokens.Space.s8) / 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    /// 6p: 요일 글자도 모두 옅은 회색(일요일 빨강 없음)
    private var quietWeekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(WorkCalendarLayout.weekdayNames, id: \.self) { name in
                Text(name).pumText(.caption2, weight: .regular)
                    .foregroundStyle(PumColor.textDisabled)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(WorkCalendarLayout.weekdayNames.enumerated()), id: \.offset) { i, name in
                // 목업 11px 400 → caption2(11), 굵기만 regular
                Text(name).pumText(.caption2, weight: .regular)
                    .foregroundStyle(i == 0 ? PumColor.statusDanger : PumColor.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true) // 칸마다 요일을 읽어 준다
    }

    private var grid: some View {
        let layout = state.layout
        return VStack(spacing: WorkCalendarMetrics.rowGap) {
            ForEach(0..<layout.weekCount, id: \.self) { week in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<WorkCalendarLayout.columns, id: \.self) { col in
                        cell(layout, slot: week * WorkCalendarLayout.columns + col)
                    }
                }
            }
        }
    }

    @ViewBuilder private func cell(_ layout: WorkCalendarLayout, slot: Int) -> some View {
        if let d = layout.day(atSlot: slot) {
            let isToday = state.today == d
            WorkCalendarDayCell(
                day: d, isSunday: layout.isSunday(d), isToday: isToday, mark: state.marks[d],
                label: layout.accessibilityLabel(day: d, mark: state.marks[d], isToday: isToday),
                action: { onSelectDay(d) })
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: WorkCalendarMetrics.cellHeight)
                .accessibilityHidden(true)
        }
    }

    private var legend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s14) {
                ForEach(WorkCalendarDot.allCases, id: \.self) { legendItem($0) }
            }
            VStack(spacing: PumTokens.Space.s4) {
                HStack(spacing: PumTokens.Space.s12) { legendItem(.confirmed); legendItem(.planned) }
                HStack(spacing: PumTokens.Space.s12) { legendItem(.substitute); legendItem(.absent) }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("범례: " + WorkCalendarDot.allCases.map(\.title).joined(separator: ", ")))
    }

    private func legendItem(_ dot: WorkCalendarDot) -> some View {
        HStack(spacing: PumTokens.Space.s4) {
            WorkCalendarDotView(dot: dot)
            Text(dot.title).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                .fixedSize()
        }
    }

    // MARK: 선택한 날

    private var selectedCard: some View {
        let s = state.selected
        return PumCard {
            Button(action: onOpenDetail) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(spacing: PumTokens.Space.s2) {
                        Text(s.weekday).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        // 목업 19px 700 → title3(20)
                        Text("\(s.day)").pumText(.title3).foregroundStyle(PumColor.textPrimary)
                    }
                    .frame(width: WorkCalendarMetrics.dateBox) // 원문 날짜 상자 44 · 가운데
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s6) {
                                actual(s); planned(s)
                            }
                            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                                actual(s); planned(s)
                            }
                        }
                        Text(s.recognizedText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    PumBadge(text: s.statusText, kind: .done)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled)
                }
                .padding(.vertical, PumTokens.Space.s14)
                .padding(.horizontal, PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(state.layout.month)월 \(s.day)일 \(s.weekday)요일, \(s.actualRange), \(s.plannedText), \(s.recognizedText), \(s.statusText)"))
            .accessibilityHint(Text("근무 상세를 열어요"))
        }
    }

    private func actual(_ s: WorkCalendarSelectedDay) -> some View {
        Text(s.actualRange).pumText(.headline).foregroundStyle(PumColor.textPrimary)
    }

    private func planned(_ s: WorkCalendarSelectedDay) -> some View {
        Text(s.plannedText).pumText(.caption, weight: .medium).foregroundStyle(PumColor.textSecondary)
    }

    // MARK: 월 요약

    private var summaryCard: some View {
        let m = state.summary
        return PumCard {
            VStack(spacing: PumTokens.Space.s12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        summaryTitle(m.title)
                        Spacer(minLength: PumTokens.Space.s8)
                        summaryNote(m.confirmedText)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        summaryTitle(m.title)
                        summaryNote(m.confirmedText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // 큰 글자에서 3칸이 좁으면 값이 쪼개지지 않도록 세로로
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                        stat("근무일", m.workDaysText)
                        stat("총 근무", m.totalText)
                        stat("연장", m.overtimeText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        stat("근무일", m.workDaysText)
                        stat("총 근무", m.totalText)
                        stat("연장", m.overtimeText)
                    }
                }
                VStack(spacing: 0) {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                HStack(alignment: .firstTextBaseline) {
                    Text("예상 급여").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    // 목업 18px 700 → headline(17) bold: 20(title3)보다 1 차이로 가깝다
                    Text(m.payText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.statusDone)
                }
                .padding(.top, PumTokens.Space.s12) // 원문: 구분선 아래 padding-top 12
                .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, PumTokens.Space.s16)
            .padding(.horizontal, PumTokens.Space.s18)
        }
    }

    private func summaryTitle(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    private func summaryNote(_ s: String) -> some View {
        Text(s).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
            // 목업 16px 700 → headline(17) bold
            Text(value).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7) // 「82시간 30분」이 쪼개지지 않게
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview("1g") { WorkCalendarView() }
#Preview("6p") { WorkCalendarView(state: .empty) }
#Preview("6p · 큰 글자") { WorkCalendarView(state: .empty).dynamicTypeSize(.xxxLarge) }
#Preview("1g · 큰 글자") { WorkCalendarView().dynamicTypeSize(.xxxLarge) }
