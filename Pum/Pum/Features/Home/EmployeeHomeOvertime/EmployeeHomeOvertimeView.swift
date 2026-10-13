// UI-IOS-1ak · REQ-024 · REQ-026 — 확정 · 연장 근무 중: 예정 초과분이 그냥 쌓인다. 묻는 팝업 · 확인 없음, 자동 퇴근 없음
import SwiftUI

struct EmployeeHomeOvertimeView: View {
    var state: EmployeeHomeOvertimeState = .sample
    /// true면 분이 바뀔 때마다 실제 시각으로 갱신(초 표시 없음). 미리보기 · 테스트는 false
    var liveClock = false
    var onClockOut: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        content
            .background(PumColor.bgApp)
            .safeAreaInset(edge: .bottom, spacing: 0) { PumTabBar(items: PumTabItem.employeeTabs, selection: $tab) }
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

    private func scroll(_ s: EmployeeHomeOvertimeState) -> some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s16) {
                header(s)
                OvertimeCard(state: s, onClockOut: onClockOut)
                OvertimeSoFarCard(state: s)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
    }

    private func header(_ s: EmployeeHomeOvertimeState) -> some View {
        HStack {
            PumWorkplaceChip(name: s.workplaceName, initial: s.workplaceInitial) {}
            Spacer()
            PumIconButton(systemImage: "bell", label: "알림", showsDot: s.hasUnreadNotification) {}
        }
        .padding(.vertical, -(PumTokens.Size.tapMin - Self.topRowHeight) / 2) // 원문 줄 높이 40(누름 44 유지)
    }

    /// 원문 맨 위 줄(칩 · 알림) 높이 40
    private static let topRowHeight: CGFloat = 40
}

/// 먹색 카드 — 연장 근무 중 · 경과 · 진행 막대 · 퇴근하기
struct OvertimeCard: View {
    let state: EmployeeHomeOvertimeState
    var onClockOut: () -> Void = {}

    /// 목업 주황 #F5B57A → 토큰에서 가장 가까운 주황 amber-200(#E8B98F, status-attention-line) (DEC-005)
    static let overtimeTint = PumColor.statusAttentionLine
    /// 목업 점 지름 8 → space-8
    private let dotSize = PumTokens.Space.s8
    /// 원문 퇴근하기 버튼 높이 50
    private let clockOutHeight: CGFloat = 50

    var body: some View {
        // 원문 간격: 위 줄–경과 14, 경과–막대 18, 막대–아래 줄 10, 아래 줄–버튼 18
        VStack(alignment: .leading, spacing: PumTokens.Space.s18) {
            VStack(alignment: .leading, spacing: 0) {
                top
                elapsed.padding(.top, PumTokens.Space.s14)
                OvertimeProgressBar(state: state).padding(.top, PumTokens.Space.s18)
                bottomLine.padding(.top, PumTokens.Space.s10)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(OvertimeFormat.cardLabel(
                elapsed: state.elapsedMinutes,
                plannedEnd: HomeFormat.clock(state.plan.endMinute),
                overtime: state.overtimeMinutes)))
            clockOutButton
        }
        .padding(PumTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous)) // 원문 모서리 16
    }

    private var top: some View {
        HStack(spacing: PumTokens.Space.s8) {
            Circle().fill(Self.overtimeTint).frame(width: dotSize, height: dotSize)
            // 목업 14px 600 흰색 85% → footnote(13) 다음 단계 callout(14) semibold, 색은 흰색(85%는 토큰 밖)
            Text("연장 근무 중").pumText(.callout, weight: .semibold).foregroundStyle(.white)
            Spacer(minLength: PumTokens.Space.s8)
            Text(state.dateText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textOnInverseSecondary)
        }
    }

    /// 큰 경과 「4:15」(display) + 「근무」(title3 medium)
    private var elapsed: some View {
        HStack(alignment: .lastTextBaseline, spacing: PumTokens.Space.s6) { // 원문 「근무」 앞 6
            Text(OvertimeFormat.clockStyle(state.elapsedMinutes)).pumText(.display).pumBigNumberLineHeight().foregroundStyle(.white)
            Text("근무").pumText(.title3, weight: .medium).foregroundStyle(PumColor.textOnInverseSecondary)
        }
        .lineLimit(1).minimumScaleFactor(0.6) // 접근성 큰 글자에서 잘리지 않게 한 줄 유지 · 축소
    }

    private var bottomLine: some View {
        // 큰 글자에서 한 줄에 안 들어가면 위아래로
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                clockIn
                Spacer(minLength: PumTokens.Space.s8)
                planned
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                clockIn
                planned
            }
        }
    }

    private var clockIn: some View {
        Text("\(HomeFormat.clock(state.clockInMinute)) 출근")
            .pumText(.footnote).foregroundStyle(PumColor.textOnInverseSecondary)
    }

    private var planned: some View {
        HStack(spacing: 0) {
            Text("예정 퇴근 \(HomeFormat.clock(state.plan.endMinute)) · ")
                .pumText(.footnote).foregroundStyle(PumColor.textOnInverseSecondary)
            Text(OvertimeFormat.plusClock(state.overtimeMinutes))
                .pumText(.footnote, weight: .bold).foregroundStyle(Self.overtimeTint)
        }
    }

    /// 흰 바탕 · 먹색 글자 버튼(먹색 카드 위라 공통 DARK 버튼 대신). 높이는 C1과 같은 토큰, 모서리는 목업 lg
    private var clockOutButton: some View {
        Button(action: onClockOut) {
            Text("퇴근하기")
                .pumText(.body, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: clockOutHeight)
                .background(.white, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 진행 막대 — 예정 구간(연초록) + 초과 구간(주황), 높이 · 모서리는 1av와 같음
struct OvertimeProgressBar: View {
    let state: EmployeeHomeOvertimeState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let barHeight: CGFloat = PumTokens.Space.s6 // 원문 막대 높이 6

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
        GeometryReader { geo in
            let w = geo.size.width
            let over = w * CGFloat(state.overtimeRatio)
            // 원문 1ak: 예정 구간(연초록)과 초과 구간(주황)이 틈 없이 이어진 한 막대
            HStack(spacing: 0) {
                Rectangle().fill(PumTokens.ColorToken.green300) // 목업 연초록 → green-300
                    .frame(width: max(0, w - over))
                if over > 0 {
                    Rectangle().fill(OvertimeCard.overtimeTint).frame(width: over)
                }
            }
        }
        .frame(height: barHeight)
        .clipShape(shape)
        // M7: 값이 바뀔 때만. 동작 줄이기면 즉시
        .animation(reduceMotion ? nil : PumMotion.progress, value: state.nowMinute)
        .accessibilityHidden(true) // 의미는 카드 한 문장에 포함
    }
}

/// 흰 카드 「오늘 지금까지」 — 예정 근무 · 예정 초과 · 인정 예상
struct OvertimeSoFarCard: View {
    let state: EmployeeHomeOvertimeState

    var body: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                Text("오늘 지금까지").pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                // 좁거나 큰 글자면 세로로
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 0) { cells } // 원문 3칸 균등, 틈 없음
                    VStack(alignment: .leading, spacing: PumTokens.Space.s12) { cells }
                }
            }
            .padding(.vertical, PumTokens.Space.s16)
            .padding(.horizontal, PumTokens.Space.s18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var cells: some View {
        cell("예정 근무", HomeFormat.hours(state.plan.plannedPaidMinutes), PumColor.textPrimary)
        cell("예정 초과", OvertimeFormat.plusDuration(state.overtimeMinutes), PumColor.statusAttention)
        // 서버(엔진) 값 그대로 — 화면에서 계산하지 않는다
        // 「~」는 「이상(더 늘 수 있음)」 — VoiceOver가 물결표로 읽지 않게 따로 읽힘 문장
        cell("인정 예상", "\(PumFormat.amount(state.recognizedPayEstimate))원~", PumColor.statusDone,
             spoken: "인정 예상 \(PumFormat.amount(state.recognizedPayEstimate))원 이상")
    }

    private func cell(_ title: String, _ value: String, _ color: Color, spoken: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
            Text(value).pumText(.body, weight: .bold).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spoken.map { Text($0) } ?? Text("\(title) \(value)"))
    }
}

#Preview("1ak") { EmployeeHomeOvertimeView() }
#Preview("1ak · 큰 글자") { EmployeeHomeOvertimeView().dynamicTypeSize(.xxxLarge) }
