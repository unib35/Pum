// UI-IOS-1f · C8 변형 — 한 줄 타임라인: 회색 기준선 위에 실제 막대(파랑·휴게 연파랑)와 겹친 예정 점선 테두리
import SwiftUI

struct ClockOutDoneTimelineView: View {
    let record: ClockOutDoneRecord
    var axis = WorkTimelineAxis()

    // 목업 막대 높이 · 점선 패턴 · 기준선 두께 (DEC-005: 토큰 단계에 가장 가까운 값)
    private let barHeight: CGFloat = PumTokens.Space.s16
    private let plannedOutset: CGFloat = PumTokens.Space.s8
    private let dashPattern: [CGFloat] = [PumTokens.Space.s4, PumTokens.Space.s2]
    private let dashLine: CGFloat = 1.5
    private let baselineHeight: CGFloat = PumTokens.Space.s4

    var body: some View {
        VStack(spacing: PumTokens.Space.s8) {
            track
            ticks
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.timelineLabel))
    }

    private var track: some View {
        let planned = axis.span(record.plannedStart, record.plannedEnd)
        let actual = axis.span(record.actualStart, record.actualEnd)
        let brk = axis.span(record.breakStart, record.breakStart + record.breakMinutes)
        return GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(PumColor.surfaceFill)
                    .frame(width: w, height: baselineHeight)
                Capsule().fill(PumColor.accent)
                    .frame(width: w * actual.length, height: barHeight)
                    .offset(x: w * actual.start)
                // 휴게: 실제 막대 안을 네모로 끊은 구간
                Rectangle().fill(PumColor.accentOnInverse)
                    .frame(width: w * brk.length, height: barHeight)
                    .offset(x: w * brk.start)
                // 예정: 실제 막대 위에 겹친 점선 테두리(막대보다 살짝 키워 겹침이 보이게)
                Capsule().strokeBorder(PumColor.textDisabled, style: StrokeStyle(lineWidth: dashLine, dash: dashPattern))
                    .frame(width: w * planned.length, height: barHeight + plannedOutset)
                    .offset(x: w * planned.start)
            }
            .frame(height: geo.size.height, alignment: .leading)
        }
        .frame(height: barHeight + plannedOutset)
    }

    private var ticks: some View {
        // 큰 글자에서 8개가 겹치면 양 끝만 남긴다
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(axis.tickLabels.enumerated()), id: \.offset) { i, label in
                    tick(label)
                    if i < axis.tickLabels.count - 1 { Spacer(minLength: PumTokens.Space.s2) }
                }
            }
            HStack {
                tick(axis.tickLabels.first ?? "")
                Spacer()
                tick(axis.tickLabels.last ?? "")
            }
        }
    }

    private func tick(_ s: String) -> some View {
        Text(s).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary).lineLimit(1).fixedSize()
    }
}
