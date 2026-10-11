// UI-IOS-1au — 확정 · 근무 없는 날: 하단 버튼 없음(출근하기 없음), 탭 바만 하단 고정
// 순서: 칩 → 주간 스트립 → 오늘(근무 없음 · 다음 근무) → 그다음 근무 → 이번 달
import SwiftUI

struct EmployeeHomeNoShiftView: View {
    var state: NoShiftHomeState = .sample
    var onUnplannedClockIn: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                WeekStripCard(title: state.weekTitle, summary: state.weekSummary, days: state.week)
                NoShiftTodayCard(state: state, onUnplannedClockIn: onUnplannedClockIn)
                UpcomingShiftsCard(shifts: state.upcoming)
                MonthSummaryCard(state: state.monthCardState)
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
        HStack {
            PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
            Spacer()
            PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification) {}
        }
        .padding(.top, PumTokens.Space.s8)
    }
}

struct NoShiftTodayCard: View {
    let state: NoShiftHomeState
    var onUnplannedClockIn: () -> Void = {}

    var body: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                // 큰 글자에서 제목과 배지가 한 줄에 안 들어가면 위아래로
                ViewThatFits(in: .horizontal) {
                    HStack {
                        title
                        Spacer(minLength: PumTokens.Space.s8)
                        PumBadge(text: "근무 없음", kind: .waiting)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        title
                        PumBadge(text: "근무 없음", kind: .waiting)
                    }
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(state.nextShiftCaption).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    // 목업 26px → 토큰 title2(24)·title1(28)이 같은 거리. 좁은 폭에서 안 잘리도록 title2 (DEC-005)
                    Text(state.nextShiftRange).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                }
                .accessibilityElement(children: .combine)
                Text(state.plannedSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            // 디자인 1au: 구분선은 카드 끝에서 끝까지, 이동 행은 카드 바닥(C5 이동 행)
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            Button(action: onUnplannedClockIn) {
                HStack {
                    Text("예정에 없는 출근")
                        .pumText(.footnote, weight: .semibold)
                        .foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    Image(systemName: "chevron.right")
                        .pumText(.caption2)
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, PumTokens.Space.s20)
                .frame(minHeight: PumTokens.Size.tapMin + PumTokens.Space.s8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("예정에 없는 출근"))
        }
    }

    private var title: some View {
        Text(state.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }
}

#Preview("1au") { EmployeeHomeNoShiftView() }
#Preview("1au · 큰 글자") { EmployeeHomeNoShiftView().dynamicTypeSize(.xxxLarge) }
