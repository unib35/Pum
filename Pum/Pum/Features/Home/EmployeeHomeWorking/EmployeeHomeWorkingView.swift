// UI-IOS-1av · REQ-105 · REQ-024 — 확정 · 근무 중: 지난 시간 · 진행 막대 · 퇴근 버튼은 엄지 영역에 고정 (그다음 근무 카드 없음)
import SwiftUI

struct EmployeeHomeWorkingView: View {
    var state: EmployeeHomeWorkingState = .sample
    /// true면 분이 바뀔 때마다 실제 시각으로 갱신(초 표시 없음). 미리보기 · 테스트는 false
    var liveClock = false
    var onClockOut: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        content
            .background(PumColor.bgApp)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottom }
    }

    @ViewBuilder
    private var content: some View {
        if liveClock {
            TimelineView(.everyMinute) { ctx in
                scroll(state.with(now: WorkingFormat.minuteOfDay(ctx.date)))
            }
        } else {
            scroll(state)
        }
    }

    private func scroll(_ s: EmployeeHomeWorkingState) -> some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header(s.base)
                WeekStripCard(title: s.base.weekTitle, summary: s.base.weekSummary, days: s.base.week)
                WorkingTodayCard(state: s)
                MonthSummaryCard(state: s.base)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
    }

    private var bottom: some View {
        VStack(spacing: 0) {
            VStack(spacing: PumTokens.Space.s10) {
                PumButton(title: "퇴근하기", kind: .dark, action: onClockOut)
                Text("퇴근할 때 눌러주세요 · 예정 \(HomeFormat.clock(state.plan.endMinute))")
                    .pumText(.footnote)
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    private func header(_ b: EmployeeHomeState) -> some View {
        HStack {
            PumWorkplaceChip(name: b.workplaceName, initial: b.workplaceInitial) {}
            Spacer()
            PumIconButton(systemImage: "bell", label: "알림", showsDot: b.hasUnreadNotification) {}
        }
        .padding(.top, PumTokens.Space.s8)
    }
}

extension EmployeeHomeWorkingState {
    func with(now: Int) -> EmployeeHomeWorkingState {
        var copy = self
        copy.nowMinute = now
        return copy
    }
}

struct WorkingTodayCard: View {
    let state: EmployeeHomeWorkingState

    var body: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                HStack {
                    Text(state.base.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Spacer()
                    PumBadge(text: "근무 중", kind: .active)
                }
                // 큰 글자 설정에서 한 줄에 안 들어가면 위아래로(동적 글자 크기)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .lastTextBaseline) {
                        elapsed
                        Spacer(minLength: PumTokens.Space.s8)
                        times(alignment: .trailing)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        elapsed
                        times(alignment: .leading)
                    }
                }
                WorkProgressBar(plan: state.plan, nowMinute: state.nowMinute)
                Text("오늘 예정 \(HomeFormat.hours(state.plan.plannedPaidMinutes)) · \(PumFormat.amount(state.plannedPay))원")
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s20)
        }
    }

    /// 숫자는 크게(display), 단위는 작게(title3)
    private var elapsed: some View {
        let p = WorkingFormat.parts(state.elapsedMinutes)
        return HStack(alignment: .lastTextBaseline, spacing: PumTokens.Space.s4) {
            if p.hours > 0 {
                number("\(p.hours)")
                unit("시간")
            }
            number(WorkingFormat.minuteText(p))
            unit("분")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(WorkingFormat.elapsedLabel(state.elapsedMinutes)))
    }

    private func number(_ s: String) -> some View {
        Text(s).pumText(.display).foregroundStyle(PumColor.textPrimary)
    }

    private func unit(_ s: String) -> some View {
        Text(s).pumText(.title3).foregroundStyle(PumColor.textPrimary)
    }

    private func times(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: PumTokens.Space.s2) {
            Text("\(HomeFormat.clock(state.clockInMinute)) 출근")
                .pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
                Text(HomeFormat.clock(state.plan.endMinute)).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text("퇴근 예정").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("1av") { EmployeeHomeWorkingView() }
#Preview("1av · 큰 글자") { EmployeeHomeWorkingView().dynamicTypeSize(.xxxLarge) }
#Preview("1av · 예정 퇴근 이후") { EmployeeHomeWorkingView(state: EmployeeHomeWorkingState.sample.with(now: 22 * 60 + 20)) }
