// UI-IOS-1h · C8 예정 vs 실제 — 위 줄 예정(점선 캡슐), 기준선, 아래 줄 실제(진한 파랑) + 휴게(연파랑)
import SwiftUI

struct WorkTimelineView: View {
    let record: WorkDetailRecord
    var axis = WorkTimelineAxis()

    // 목업 막대 높이 · 점선 패턴을 이름 붙여 둔 값(DEC-005: 토큰 단계에 가장 가까운 값)
    private let barHeight: CGFloat = PumTokens.Space.s14
    private let dashPattern: [CGFloat] = [PumTokens.Space.s4, PumTokens.Space.s2]
    private let dashLine: CGFloat = 1.5
    /// 원문 트랙: 높이 40 · 예정 위 4 · 기준선 위 19(두께 2) · 실제 위 22
    private let trackHeight = PumTokens.Space.s24 + PumTokens.Space.s16
    private let plannedTop = PumTokens.Space.s4
    private let baselineTop = PumTokens.Space.s18 + 1
    private let actualTop = PumTokens.Space.s20 + PumTokens.Space.s2
    private let barRadius = PumTokens.Radius.xs

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            legend
                .padding(.bottom, PumTokens.Space.s10)
            track
            ticks
                .padding(.top, PumTokens.Space.s4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.timelineLabel))
    }

    private var planned: some View {
        RoundedRectangle(cornerRadius: barRadius, style: .continuous)
            .strokeBorder(PumColor.textDisabled, style: StrokeStyle(lineWidth: dashLine, dash: dashPattern))
    }

    private var actual: some View { RoundedRectangle(cornerRadius: barRadius, style: .continuous).fill(PumColor.accent) }

    /// 예정(위) · 기준선 · 실제(아래) 한 트랙. 폭에 비율을 곱해 놓는다.
    private var track: some View {
        let sp = axis.span(record.plannedStart, record.plannedEnd)
        let ac = axis.span(record.actualStart, record.actualEnd)
        let b = axis.span(record.breakStart, record.breakStart + record.breakMinutes)
        return GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                Rectangle().fill(PumColor.borderHairline)
                    .frame(width: w, height: PumTokens.Space.s2)
                    .offset(y: baselineTop)
                planned
                    .frame(width: w * sp.length, height: barHeight)
                    .offset(x: w * sp.start, y: plannedTop)
                actual
                    .frame(width: w * ac.length, height: barHeight)
                    .offset(x: w * ac.start, y: actualTop)
                // 디자인 1h: 휴게는 실제 막대 안을 네모로 끊은 구간
                Rectangle().fill(PumColor.accentOnInverse)
                    .frame(width: w * b.length, height: barHeight)
                    .offset(x: w * b.start, y: actualTop)
            }
        }
        .frame(height: trackHeight)
    }

    private var ticks: some View {
        // 큰 글자에서 8개가 겹치면 양 끝만 남긴다
        ViewThatFits(in: .horizontal) {
            // 디자인 1h: 눈금 라벨은 양 끝 정렬(첫 라벨은 축 시작, 끝 라벨은 축 끝)
            HStack(spacing: 0) {
                ForEach(Array(axis.tickLabels.enumerated()), id: \.offset) { i, label in
                    edgeTick(label)
                    if i < axis.tickLabels.count - 1 { Spacer(minLength: PumTokens.Space.s2) }
                }
            }
            HStack {
                edgeTick(axis.tickLabels.first ?? "")
                Spacer()
                edgeTick(axis.tickLabels.last ?? "")
            }
        }
    }

    /// 양 끝만 남길 때는 축 끝에 붙인다(가운데 정렬 칸을 쓰지 않음)
    private func edgeTick(_ s: String) -> some View {
        Text(s).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary).lineLimit(1).fixedSize()
    }

    private var legend: some View {
        HStack(spacing: PumTokens.Space.s16) {
            legendItem("예정") { planned }
            legendItem("실제") { actual }
            legendItem("휴게") { Capsule().fill(PumColor.accentOnInverse) }
        }
    }

    private func legendItem<S: View>(_ title: String, @ViewBuilder swatch: () -> S) -> some View {
        HStack(spacing: PumTokens.Space.s6) {
            swatch().frame(width: PumTokens.Space.s14, height: PumTokens.Space.s8)
            Text(title).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }
}
