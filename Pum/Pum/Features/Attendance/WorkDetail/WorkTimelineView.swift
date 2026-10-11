// UI-IOS-1h · C8 예정 vs 실제 — 위 줄 예정(점선 캡슐), 기준선, 아래 줄 실제(진한 파랑) + 휴게(연파랑)
import SwiftUI

struct WorkTimelineView: View {
    let record: WorkDetailRecord
    var axis = WorkTimelineAxis()

    // 목업 막대 높이 · 점선 패턴을 이름 붙여 둔 값(DEC-005: 토큰 단계에 가장 가까운 값)
    private let barHeight: CGFloat = PumTokens.Space.s16
    private let dashPattern: [CGFloat] = [PumTokens.Space.s4, PumTokens.Space.s2]
    private let dashLine: CGFloat = 1.5
    private let rowGap: CGFloat = PumTokens.Space.s8

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            legend
            VStack(spacing: rowGap) {
                lane(record.plannedStart, record.plannedEnd, withBreak: false) { planned }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                lane(record.actualStart, record.actualEnd, withBreak: true) { actual }
            }
            ticks
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.timelineLabel))
    }

    private var planned: some View {
        Capsule().strokeBorder(PumColor.textDisabled, style: StrokeStyle(lineWidth: dashLine, dash: dashPattern))
    }

    private var actual: some View { Capsule().fill(PumColor.accent) }

    /// 축 위의 구간 하나. 폭에 비율을 곱해 놓는다.
    private func lane<S: View>(_ start: Int, _ end: Int, withBreak: Bool, @ViewBuilder shape: () -> S) -> some View {
        let sp = axis.span(start, end)
        let b = axis.span(record.breakStart, record.breakStart + record.breakMinutes)
        let content = shape()
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                content
                    .frame(width: geo.size.width * sp.length, height: barHeight)
                    .offset(x: geo.size.width * sp.start)
                if withBreak {
                    Capsule().fill(PumColor.accentOnInverse)
                        .frame(width: geo.size.width * b.length, height: barHeight)
                        .offset(x: geo.size.width * b.start)
                }
            }
        }
        .frame(height: barHeight)
    }

    private var ticks: some View {
        // 큰 글자에서 8개가 겹치면 양 끝만 남긴다
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) { ForEach(axis.tickLabels, id: \.self) { tick($0) } }
            HStack { tick(axis.tickLabels.first ?? ""); Spacer(); tick(axis.tickLabels.last ?? "") }
        }
    }

    private func tick(_ s: String) -> some View {
        Text(s).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }

    private var legend: some View {
        HStack(spacing: PumTokens.Space.s12) {
            legendItem("예정") { planned }
            legendItem("실제") { actual }
            legendItem("휴게") { Capsule().fill(PumColor.accentOnInverse) }
        }
    }

    private func legendItem<S: View>(_ title: String, @ViewBuilder swatch: () -> S) -> some View {
        HStack(spacing: PumTokens.Space.s6) {
            swatch().frame(width: PumTokens.Space.s20, height: PumTokens.Space.s8)
            Text(title).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }
}
