// UI-IOS-2f · REQ-005 · REQ-006 · REQ-105 — 개인 모드 홈: 확정 홈(1at)과 같은 순서 · 점선 「내 기록」 · 누른 시각 그대로 저장, 자유 수정
// 1at(EmployeeHomeView)과 같은 토큰 · 크기 · 구조. 1at의 하위 뷰는 재사용하고(WeekStripCard · ShiftTimeline), private이거나 모양이 달라진 부분만 여기에 둔다.
// 「출근 기록」은 어떤 상태에서도 막지 않는다(REQ-029) — 비활성 · 로딩 상태를 두지 않는다.
import SwiftUI

struct PersonalHomeView: View {
    var state: PersonalHomeState = .sample
    var onSwitchWorkplace: () -> Void = {}
    var onBell: () -> Void = {}
    var onClockIn: () -> Void = {}
    var onManualEntry: () -> Void = {}
    var onOpenCalendar: () -> Void = {}
    var onOpenPayBasis: () -> Void = {}
    var onInviteOwner: () -> Void = {}
    var onSelectTab: (String) -> Void = { _ in }
    @State private var tab = "home"

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                WeekStripCard(title: state.weekTitle, summary: state.weekSummary, days: state.week, dotStyle: .muted) // 원문: 개인 기록 점은 회색
                PersonalTodayCard(state: state)
                PersonalMonthCard(state: state, onOpenPayBasis: onOpenPayBasis)
                if !state.recent.isEmpty {
                    PersonalRecentCard(records: state.recent, onOpenCalendar: onOpenCalendar)
                }
                PersonalInviteCard(action: onInviteOwner)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                VStack(spacing: PumTokens.Space.s4) {
                    PumButton(title: "출근 기록", action: onClockIn)
                    Button(action: onManualEntry) {
                        Text("시간 직접 입력")
                            .pumText(.footnote, weight: .semibold)
                            .foregroundStyle(PumColor.accent)
                            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12)
                .background(PumColor.bgApp)
                PumTabBar(items: PumTabItem.employeeTabs, selection: Binding(
                    get: { tab },
                    set: { tab = $0; onSelectTab($0) }
                ))
            }
        }
    }

    private var header: some View {
        HStack {
            PersonalModeChip(name: state.workplaceName, initial: state.workplaceInitial, action: onSwitchWorkplace)
            Spacer()
            PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification, action: onBell)
        }
        .padding(.top, PumTokens.Space.s8)
    }
}

// MARK: - 점선 표시 (개인 모드 · 내 기록)

/// 점선 윤곽 — REQ-006 PERSONAL 표시. 점선 간격은 간격 토큰.
private struct PersonalDash: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(PumTokens.ColorToken.gray400,
                              style: StrokeStyle(lineWidth: 1, dash: [PumTokens.Space.s4, PumTokens.Space.s2]))
        }
    }
}

/// 사업장 칩의 개인 모드 모양 — 점선 네모 안 「개」 + 「개인 · 이름」 + ⌄. 1at 칩(PumWorkplaceChip)과 같은 크기.
/// 공통 후보: PumWorkplaceChip의 개인 모드 변형.
private struct PersonalModeChip: View {
    let name: String
    let initial: String
    let action: () -> Void
    @ScaledMetric private var tile = PumLayout.storeTileSmall

    var body: some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s8) {
                Text(initial)
                    .pumText(.caption2, weight: .bold)
                    .foregroundStyle(PumTokens.ColorToken.gray700)
                    .frame(width: tile, height: tile)
                    .modifier(PersonalDash(radius: tile * PumLayout.storeTileRadiusRatio))
                Text("개인 · \(name)").pumText(.callout).foregroundStyle(PumColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(.leading, PumTokens.Space.s8)
            .padding(.trailing, PumTokens.Space.s12)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.surfaceCard, in: Capsule())
            .pumRing(.hairline, cornerRadius: PumTokens.Size.tapMin / 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("개인 모드, \(name)"))
        .accessibilityHint(Text("사업장을 바꿔요"))
    }
}

/// 점선 「내 기록」 — 본인이 입력 · 자유 수정하는 기록(REQ-006)
private struct PersonalRecordTag: View {
    var body: some View {
        Text("내 기록")
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .semibold, relativeTo: .caption))
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .padding(.vertical, PumTokens.Space.s4)
            .padding(.horizontal, 9) // PumBadge와 같은 안쪽 여백
            .modifier(PersonalDash(radius: PumTokens.Radius.sm))
            .accessibilityLabel(Text("내 기록"))
    }
}

// MARK: - 오늘 카드

/// 1at TodayShiftCard와 같은 구조. 1at과 중복 — 공통 후보(1at 쪽이 EmployeeHomeState에 묶여 있어 재사용 불가).
private struct PersonalTodayCard: View {
    let state: PersonalHomeState

    var body: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                // 큰 글자에서 제목과 배지가 한 줄에 안 들어가면 위아래로
                ViewThatFits(in: .horizontal) {
                    HStack {
                        title
                        Spacer(minLength: PumTokens.Space.s8)
                        badges
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        title
                        badges
                    }
                }
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
                ShiftTimeline(plan: state.today)
                Text("내 시급 \(PumFormat.amount(state.hourlyWage))원 기준 · \(PumFormat.amount(state.plannedPay))원 예정")
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(PumTokens.Space.s20)
        }
    }

    private var title: some View {
        Text(state.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    private var badges: some View {
        HStack(spacing: PumTokens.Space.s8) {
            PersonalRecordTag()
            PumBadge(text: "출근 전", kind: .waiting)
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
            Text("내 예정").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
                Text(HomeFormat.clock(state.today.startMinute)).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                Text("· " + HomeFormat.untilStart(state.minutesUntilStart))
                    .pumText(.callout, weight: .medium).foregroundStyle(PumColor.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 이번 달

/// 1at MonthSummaryCard와 같은 구조(1at과 중복 — 공통 후보). 「계산 근거 ›」는 동작 클로저를 받는다.
private struct PersonalMonthCard: View {
    let state: PersonalHomeState
    let onOpenPayBasis: () -> Void

    var body: some View {
        PumCard {
            HStack(spacing: 0) {
                cell(label: "\(state.monthTitle) 근무 예상", value: HomeFormat.hours(state.monthPlannedMinutes)) {
                    Text(state.monthDaysSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                Rectangle().fill(PumColor.borderHairline).frame(width: 1)
                cell(label: "\(state.monthTitle) 예상 급여", value: PumFormat.amount(state.monthExpectedPay) + "원") {
                    Button(action: onOpenPayBasis) {
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

// MARK: - 최근 기록

/// 1at 「그다음 근무」 카드와 같은 모양. 값은 지난 내 기록(PERSONAL).
private struct PersonalRecentCard: View {
    let records: [PersonalRecord]
    let onOpenCalendar: () -> Void

    var body: some View {
        PumCard {
            HStack {
                Text("최근 기록").pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Spacer()
                Button(action: onOpenCalendar) {
                    Text("캘린더").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle().inset(by: -PumTokens.Space.s12)) // 터치 영역 44pt 이상
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.top, PumTokens.Space.s16)
            .padding(.bottom, PumTokens.Space.s4)
            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                HStack(spacing: PumTokens.Space.s16) {
                    Text(record.id).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Text(PumFormat.timeRange(record.start, record.end)).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                    Spacer()
                    Text(HomeFormat.hours(record.paidMinutes)).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                }
                .padding(.horizontal, PumTokens.Space.s16)
                .padding(.vertical, PumTokens.Space.s10)
                .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: index == 0 ? 0 : 1) }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - 사장님 초대 권유

private struct PersonalInviteCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PumCard {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text("사장님도 품을 쓰면").pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text("출퇴근이 바로 공유되고 명세서도 받아요").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("알려주기").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.accent)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textTertiary)
                        .accessibilityHidden(true)
                }
                .padding(PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("사장님에게 품을 알려요"))
    }
}

#Preview("2f") { PersonalHomeView(state: .sample) }
#Preview("2f · 큰 글자") { PersonalHomeView(state: .sample).dynamicTypeSize(.xxxLarge) }
