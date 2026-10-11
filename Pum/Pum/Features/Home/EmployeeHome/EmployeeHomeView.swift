// UI-IOS-1at · REQ-105 — 확정 · 출근 전: 주간 스트립 · 지금 시각과 남은 시간 · 이번 달 · 그다음 근무 2건 · 출근 버튼은 엄지 영역에 고정
import SwiftUI

struct EmployeeHomeView: View {
    var state: EmployeeHomeState = .sample
    var onClockIn: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                WeekStripCard(title: state.weekTitle, summary: state.weekSummary, days: state.week)
                TodayShiftCard(state: state)
                MonthSummaryCard(state: state)
                UpcomingShiftsCard(shifts: state.upcoming)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                // 출근 버튼은 엄지 영역에 고정
                VStack(spacing: PumTokens.Space.s10) {
                    PumButton(title: "출근하기", action: onClockIn)
                    Text("매장 QR 스캔 또는 위치 확인으로 기록돼요")
                        .pumText(.footnote)
                        .foregroundStyle(PumColor.textSecondary)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
                PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
            }
        }
    }

    private var header: some View {
        HStack {
            PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
            Spacer()
            PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification) {}
        }
        .padding(.top, PumTokens.Space.s8)
    }
}

// MARK: - 주간 스트립

struct WeekStripCard: View {
    let title: String
    let summary: String
    let days: [WeekDay]

    var body: some View {
        PumCard {
            VStack(spacing: PumTokens.Space.s12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Spacer()
                    Text(summary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                HStack(spacing: PumTokens.Space.s4) {
                    ForEach(days) { DayCell(day: $0) }
                }
            }
            .padding(PumTokens.Space.s16)
        }
    }
}

private struct DayCell: View {
    let day: WeekDay

    var body: some View {
        VStack(spacing: PumTokens.Space.s4) {
            Text(day.label).pumText(.caption2, weight: .regular).foregroundStyle(labelColor)
            Text("\(day.day)").pumText(.headline, weight: day.isToday ? .bold : .semibold).foregroundStyle(numberColor)
            Circle()
                .fill(day.hasShift ? (day.isToday ? PumColor.accentOnInverse : PumColor.accent) : .clear)
                .frame(width: PumLayout.dayDot, height: PumLayout.dayDot)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PumTokens.Space.s8)
        .background(day.isToday ? PumColor.surfaceInverse : .clear,
                    in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(day.label)요일 \(day.day)일\(day.hasShift ? ", 근무 있음" : "")\(day.isToday ? ", 오늘" : "")"))
    }

    private var labelColor: Color {
        if day.isToday { return PumColor.textOnInverseSecondary }
        return day.isSunday ? PumColor.statusDanger : PumColor.textSecondary
    }

    private var numberColor: Color {
        if day.isToday { return .white }
        return day.isSunday ? PumColor.statusDanger : PumColor.textPrimary
    }
}

// MARK: - 오늘 근무

struct TodayShiftCard: View {
    let state: EmployeeHomeState

    var body: some View {
        let plan = state.today
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                HStack {
                    Text(state.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Spacer()
                    PumBadge(text: "출근 전", kind: .waiting)
                }
                // 큰 글자 설정에서 한 줄에 안 들어가면 위아래로(동적 글자 크기)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .lastTextBaseline) {
                        nowClock
                        Spacer(minLength: PumTokens.Space.s8)
                        startInfo(alignment: .trailing)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        nowClock
                        startInfo(alignment: .leading)
                    }
                }
                ShiftTimeline(plan: plan)
                Text("인정 근무 \(HomeFormat.hours(plan.plannedPaidMinutes)) · \(PumFormat.amount(plan.plannedPay(hourlyWage: state.hourlyWage)))원 예정")
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s20)
        }
    }

    private var nowClock: some View {
        Text(HomeFormat.clock(state.nowMinute))
            .pumText(.display)
            .foregroundStyle(PumColor.textPrimary)
            .accessibilityLabel(Text("지금 \(HomeFormat.clock(state.nowMinute))"))
    }

    private func startInfo(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: PumLayout.tabLabelGap) {
            Text("출근 예정").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
                Text(HomeFormat.clock(state.today.startMinute)).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                Text("· " + HomeFormat.untilStart(state.minutesUntilStart))
                    .pumText(.callout, weight: .medium).foregroundStyle(PumColor.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// C8 타임라인 — 예정 근무(연블루) · 휴게(회색) 구간과 시각
struct ShiftTimeline: View {
    let plan: ShiftPlan
    private let barHeight: CGFloat = PumTokens.Space.s8

    var body: some View {
        let total = CGFloat(plan.endMinute - plan.startMinute)
        let breakStart = plan.breakStartMinute
        VStack(spacing: PumTokens.Space.s8) {
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: PumLayout.timelineGap) {
                    if let breakStart {
                        segment(PumColor.accentSoftStrong, w * CGFloat(breakStart - plan.startMinute) / total)
                        segment(PumColor.surfaceFill, w * CGFloat(plan.breakMinutes) / total)
                        segment(PumColor.accentSoftStrong, nil)
                    } else {
                        segment(PumColor.accentSoftStrong, nil)
                    }
                }
            }
            .frame(height: barHeight)
            // 시작 · 휴게 · 끝 시각. 큰 글자에서 휴게 라벨이 양쪽과 겹치면 아래 줄로 내린다.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    Text(HomeFormat.clock(plan.startMinute))
                    Spacer(minLength: 0)
                    if let breakStart { Text(breakLabel(breakStart)) }
                    Spacer(minLength: 0)
                    Text(HomeFormat.clock(plan.endMinute))
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    HStack {
                        Text(HomeFormat.clock(plan.startMinute))
                        Spacer()
                        Text(HomeFormat.clock(plan.endMinute))
                    }
                    if let breakStart { Text(breakLabel(breakStart)) }
                }
            }
            .pumText(.caption)
            .foregroundStyle(PumColor.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("예정 \(HomeFormat.clock(plan.startMinute))부터 \(HomeFormat.clock(plan.endMinute))까지, 휴게 \(plan.breakMinutes)분"))
    }

    private func breakLabel(_ start: Int) -> String {
        "\(HomeFormat.clock(start)) 휴게 \(plan.breakMinutes)분"
    }

    @ViewBuilder
    private func segment(_ color: Color, _ width: CGFloat?) -> some View {
        let shape = RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous).fill(color)
        if let width { shape.frame(width: max(0, width - 2)) } else { shape }
    }
}

// MARK: - 이번 달

struct MonthSummaryCard: View {
    let state: EmployeeHomeState

    var body: some View {
        PumCard {
            HStack(spacing: 0) {
                cell(label: "\(state.monthTitle) 근무 예상", value: HomeFormat.hours(state.monthPlannedMinutes)) {
                    Text(state.monthDaysSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                Rectangle().fill(PumColor.borderHairline).frame(width: 1)
                cell(label: "\(state.monthTitle) 예상 급여", value: PumFormat.amount(state.monthExpectedPay) + "원") {
                    Button {} label: {
                        Text("계산 근거 ›").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle().inset(by: -PumTokens.Space.s12)) // 터치 영역 44pt 이상
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cell<Footer: View>(label: String, value: String, @ViewBuilder footer: () -> Footer) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(label).pumText(.caption, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(value).pumText(.title3).foregroundStyle(PumColor.textPrimary).minimumScaleFactor(0.8).lineLimit(1)
            footer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PumTokens.Space.s16)
    }
}

// MARK: - 그다음 근무

struct UpcomingShiftsCard: View {
    let shifts: [UpcomingShift]

    var body: some View {
        PumCard {
            HStack {
                Text("그다음 근무").pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Spacer()
                Button {} label: {
                    Text("스케줄 전체").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s12)) // 터치 영역 44pt 이상
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.top, PumTokens.Space.s16)
            .padding(.bottom, PumTokens.Space.s4)
            ForEach(Array(shifts.enumerated()), id: \.element.id) { index, shift in
                HStack(spacing: PumTokens.Space.s16) {
                    Text(shift.id).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Text(PumFormat.timeRange(shift.start, shift.end)).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                    Spacer()
                    Text(HomeFormat.hours(shift.paidMinutes)).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                }
                .padding(.horizontal, PumTokens.Space.s16)
                .padding(.vertical, PumTokens.Space.s10)
                .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: index == 0 ? 0 : 1) }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview("1at") { EmployeeHomeView() }
#Preview("1at · 큰 글자") { EmployeeHomeView().dynamicTypeSize(.xxxLarge) }
