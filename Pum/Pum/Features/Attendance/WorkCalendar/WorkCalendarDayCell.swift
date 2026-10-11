// UI-IOS-1g · 달력 날짜 칸 — 칸 폭은 고정, 글자가 커지면 줄 높이가 늘어난다
import SwiftUI

/// 화면 전용 치수(DEC-005: 토큰 단계가 없는 것만 이름 붙임)
enum WorkCalendarMetrics {
    /// 상태 점 지름 — 공통 근무일 점(5)과 같다
    static let dot = PumLayout.dayDot
    /// 빈 원 테두리
    static let hollowLine: CGFloat = 1
    /// 오늘 먹색 원 지름(글자와 함께 커진다)
    static let todayDisc = PumTokens.Space.s24 + PumTokens.Space.s4
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
    @ScaledMetric private var disc = WorkCalendarMetrics.todayDisc

    var body: some View {
        Button(action: action) {
            VStack(spacing: PumTokens.Space.s2) {
                Text("\(day)")
                    .pumText(.body, weight: isToday ? .bold : .medium)
                    .foregroundStyle(numberColor)
                    .frame(minWidth: disc, minHeight: disc)
                    .background(isToday ? PumColor.surfaceInverse : .clear, in: Circle())
                // 점 자리 높이는 고정 — 「휴무」 글자가 숫자 줄을 밀어 올리지 않게(디자인 1g)
                Color.clear
                    .frame(width: WorkCalendarMetrics.dot, height: WorkCalendarMetrics.dot)
                    .overlay(alignment: .top) { markView.fixedSize() }
            }
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    @ViewBuilder private var markView: some View {
        switch mark {
        case .dot(let d):
            WorkCalendarDotView(dot: d)
        case .dayOff:
            // 목업 9px 600 → caption2(11, 가장 작은 토큰)
            Text("휴무").pumText(.caption2).foregroundStyle(PumColor.textTertiary).lineLimit(1)
        case nil:
            Color.clear.frame(width: WorkCalendarMetrics.dot, height: WorkCalendarMetrics.dot)
        }
    }

    private var numberColor: Color {
        if isToday { return .white }
        if mark == .dayOff { return PumColor.textTertiary }
        return isSunday ? PumColor.statusDanger : PumColor.textPrimary
    }
}
