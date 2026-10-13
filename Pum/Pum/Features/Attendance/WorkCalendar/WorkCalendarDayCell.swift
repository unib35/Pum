// UI-IOS-1g · 달력 날짜 칸 — 칸 폭은 고정, 글자가 커지면 줄 높이가 늘어난다
import SwiftUI

/// 화면 전용 치수(DEC-005: 토큰 단계가 없는 것만 이름 붙임)
enum WorkCalendarMetrics {
    /// 상태 점 지름 — 원문 1g 6
    static let dot = PumTokens.Space.s6
    /// 6p 빈 상태 점 지름 — 공통 근무일 점(5)
    static let quietDot = PumLayout.dayDot
    /// 날짜 칸 높이(원문 1g: 높이 46 + 위 padding 6)와 칸 사이 세로 간격 4
    static let cellHeight = PumTokens.Space.s24 * 2 + PumTokens.Space.s4
    static let rowGap = PumTokens.Space.s4
    /// 날짜 글자 줄 높이(원문 18) · 오늘 원 위로 당김 5
    static let numberLine = PumTokens.Space.s18
    static let todayPull: CGFloat = 5
    /// 선택한 날 카드의 날짜 상자 폭(원문 44)
    static let dateBox: CGFloat = 44
    /// 빈 원 테두리
    static let hollowLine: CGFloat = 1
    /// 오늘 먹색 원 지름(글자와 함께 커진다)
    static let todayDisc = PumTokens.Space.s24 + PumTokens.Space.s6 // 원문 30
}

/// 상태 점 하나(예정만 테두리 빈 원)
struct WorkCalendarDotView: View {
    let dot: WorkCalendarDot

    var body: some View {
        Group {
            switch dot {
            case .confirmed: Circle().fill(PumColor.statusDone)
            case .planned: Circle().strokeBorder(PumColor.accent, lineWidth: WorkCalendarMetrics.hollowLine)
            case .substitute: Circle().fill(PumColor.statusAttentionDot)
            case .absent: Circle().fill(PumColor.statusDanger)
            }
        }
        .frame(width: WorkCalendarMetrics.dot, height: WorkCalendarMetrics.dot)
        .accessibilityHidden(true)
    }
}

struct WorkCalendarDayCell: View {
    let day: Int
    let isSunday: Bool
    let isToday: Bool
    let mark: WorkCalendarMark?
    let label: String
    let action: () -> Void
    /// 6p 빈 상태 전용(기본 꺼짐): 날짜 글자를 옅게, 예정 근무 날엔 연파랑 빈 원 점
    var isQuiet = false
    var showsPlannedDot = false
    @ScaledMetric private var disc = WorkCalendarMetrics.todayDisc
    @ScaledMetric private var quietDisc = PumTokens.Space.s24 + PumTokens.Space.s4
    @ScaledMetric private var line = WorkCalendarMetrics.numberLine

    var body: some View {
        Button(action: action) {
            VStack(spacing: isQuiet ? PumTokens.Space.s2 : PumTokens.Space.s4) {
                numberView
                // 점 자리 높이는 고정 — 「휴무」 글자가 숫자 줄을 밀어 올리지 않게(디자인 1g)
                Color.clear
                    .frame(width: dotSize, height: dotSize)
                    .overlay(alignment: .top) { markView.fixedSize() }
            }
            // 원문 1g: 칸 위 padding 6 · 칸 높이 52 · 위쪽 정렬
            .padding(.top, isQuiet ? 0 : PumTokens.Space.s6)
            .frame(maxWidth: .infinity, minHeight: isQuiet ? PumTokens.Size.tapMin : WorkCalendarMetrics.cellHeight,
                   alignment: isQuiet ? .center : .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private var dotSize: CGFloat { isQuiet ? WorkCalendarMetrics.quietDot : WorkCalendarMetrics.dot }

    @ViewBuilder private var numberView: some View {
        let text = Text("\(day)")
            .pumText(.body, weight: isToday ? .bold : (isQuiet ? .regular : .medium)) // 빈 상태(6p) 원문은 400
            .foregroundStyle(numberColor)
        if isQuiet {
            text.frame(minWidth: quietDisc, minHeight: quietDisc)
        } else if isToday {
            // 원문: 원 30 · 위 여백 -5
            text.frame(minWidth: disc, minHeight: disc)
                .background(PumColor.surfaceInverse, in: Circle())
                .padding(.top, -WorkCalendarMetrics.todayPull)
        } else {
            text.frame(height: line)
        }
    }

    @ViewBuilder private var markView: some View {
        switch mark {
        case .dot(let d):
            WorkCalendarDotView(dot: d)
        case .dayOff:
            // 목업 9px 600 → caption2(11, 가장 작은 토큰)
            Text("휴무").pumText(.caption2).foregroundStyle(PumColor.textTertiary).lineLimit(1)
        case nil:
            if showsPlannedDot {
                Circle().strokeBorder(PumTokens.ColorToken.blue300, lineWidth: WorkCalendarMetrics.hollowLine)
                    .frame(width: dotSize, height: dotSize)
                    .accessibilityHidden(true)
            } else {
                Color.clear.frame(width: dotSize, height: dotSize)
            }
        }
    }

    private var numberColor: Color {
        if isQuiet { return PumColor.textDisabled }
        if isToday { return .white }
        if mark == .dayOff { return PumColor.textTertiary }
        return isSunday ? PumColor.statusDanger : PumColor.textPrimary
    }
}
