// UI-IOS-1av · REQ-105 · REQ-024 — 확정 · 근무 중: 지난 시간 · 진행 막대 · 퇴근 버튼은 엄지 영역에 고정 (그다음 근무 카드 없음)
// UI-IOS-6q · REQ-029 · REQ-095 — 오프라인(state.offline != nil): 같은 화면 + 띠 · 전송 대기. 퇴근하기는 어떤 경우에도 막지 않는다.
import SwiftUI

struct EmployeeHomeWorkingView: View {
    var state: EmployeeHomeWorkingState = .sample
    /// true면 분이 바뀔 때마다 실제 시각으로 갱신(초 표시 없음). 미리보기 · 테스트는 false
    var liveClock = false
    var onClockOut: () -> Void = {}
    /// 오프라인 띠의 「다시 시도」(6q)
    var onRetryConnection: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        content
            .background(PumColor.bgApp)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottom }
            .onChange(of: state.offline != nil) { _, isOffline in
                // 오프라인이 되는 순간 한 번 읽어준다(VoiceOver). 돌아올 때는 알리지 않는다.
                if isOffline, let title = state.offline?.bannerTitle {
                    AccessibilityNotification.Announcement(title).post()
                }
            }
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
            VStack(spacing: PumTokens.Space.s14) { // 원문 1av · 6q: 블록 사이 14
                if let offline = s.offline {
                    OfflineBanner(offline: offline, onRetry: onRetryConnection)
                }
                header(s.base)
                WeekStripCard(title: s.base.weekTitle, summary: s.base.weekSummary, days: s.base.week)
                WorkingTodayCard(state: s)
                if let offline = s.offline {
                    OfflinePendingCard(offline: offline) // 이번 달 숫자는 연결 후 — 서버 숫자 카드는 그리지 않는다
                } else {
                    MonthSummaryCard(state: s.base)
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
    }

    private var bottom: some View {
        VStack(spacing: 0) {
            VStack(spacing: PumTokens.Space.s10) {
                PumButton(title: "퇴근하기", kind: .dark, action: onClockOut)
                if let offline = state.offline {
                    Text(offline.clockOutHint).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                } else {
                    Text("퇴근할 때 눌러주세요 · 예정 \(HomeFormat.clock(state.plan.endMinute))")
                        .pumText(.footnote)
                        .foregroundStyle(PumColor.textSecondary)
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s12) // 원문 1av · 6q: 아래 버튼 영역 padding 12 20 14
            .padding(.bottom, PumTokens.Space.s14)
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
            // 원문: 카드 padding 16 18 · 헤더 아래 12 · 진행 막대 위 18 · 마지막 줄 위 6
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: PumTokens.Space.s6) {
                    Text(state.base.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Spacer(minLength: PumTokens.Space.s8)
                    PumBadge(text: "근무 중", kind: .active)
                    if let offline = state.offline {
                        PumBadge(text: offline.badgeText, kind: .waiting)
                    }
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
                .padding(.top, PumTokens.Space.s12)
                WorkProgressBar(plan: state.plan, nowMinute: state.nowMinute)
                    .padding(.top, PumTokens.Space.s18)
                if let offline = state.offline {
                    Text(offline.savedNote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .padding(.top, PumTokens.Space.s6)
                } else {
                    Text("오늘 예정 \(HomeFormat.hours(state.plan.plannedPaidMinutes)) · \(PumFormat.amount(state.plannedPay))원")
                        .pumText(.caption)
                        .foregroundStyle(PumColor.textSecondary)
                        .padding(.top, PumTokens.Space.s6)
                }
            }
            .padding(.vertical, PumTokens.Space.s16)
            .padding(.horizontal, PumTokens.Space.s18)
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

/// 6q 맨 위 먹색 띠 — 제목 + 「다시 시도」(터치 44pt)
struct OfflineBanner: View {
    let offline: EmployeeHomeOffline
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: PumTokens.Space.s10) { // 원문: 띠 padding 11 14 · 글 사이 10
            Text(offline.bannerTitle)
                .pumText(.callout, weight: .semibold) // 원문 600
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onRetry) {
                Text(offline.retryTitle)
                    .pumText(.footnote, weight: .semibold)
                    .foregroundStyle(PumColor.accentOnInverse)
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
                    // 누름 44는 지키고 배치 높이만 원문(글자 줄 + 위아래 10)에 맞춘다
                    .padding(.vertical, -(PumTokens.Size.tapMin - (PumTokens.Space.s10 * 2 + PumTokens.Space.s18)) / 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("연결 \(offline.retryTitle)")) // 무엇을 다시 하는지
        }
        .padding(.horizontal, PumTokens.Space.s14)
        .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// 6q 전송 대기 카드 — 빈 원 숫자 · 건수 · 기록 요약 · 안내. VoiceOver에는 한 요소로 읽힌다.
struct OfflinePendingCard: View {
    let offline: EmployeeHomeOffline
    @ScaledMetric(relativeTo: .footnote) private var circle = PumTokens.Space.s24 + PumTokens.Space.s6

    var body: some View {
        PumCard {
            // 원문: 카드 padding 14 16 · 원 30 옆 간격 12 · 안내 위 10
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                    Text("\(offline.pending.count)")
                        .pumText(.footnote, weight: .bold)
                        .foregroundStyle(PumColor.textSecondary)
                        .frame(width: circle, height: circle)
                        .overlay(Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: 1))
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(offline.pendingTitle).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                        ForEach(Array(offline.pending.enumerated()), id: \.offset) { _, line in
                            Text(line).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(offline.pendingNote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(([offline.pendingTitle] + offline.pending + [offline.pendingNote]).joined(separator: ", ")))
    }
}

#Preview("1av") { EmployeeHomeWorkingView() }
#Preview("1av · 큰 글자") { EmployeeHomeWorkingView().dynamicTypeSize(.xxxLarge) }
#Preview("1av · 예정 퇴근 이후") { EmployeeHomeWorkingView(state: EmployeeHomeWorkingState.sample.with(now: 22 * 60 + 20)) }
#Preview("6q") { EmployeeHomeWorkingView(state: .offline) }
#Preview("6q · 큰 글자") { EmployeeHomeWorkingView(state: .offline).dynamicTypeSize(.xxxLarge) }
