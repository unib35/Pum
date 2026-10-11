// UI-IOS-1av — 진행 막대: 1at 타임라인과 같은 구간에 지난 부분을 진한 파랑으로 채운다
import SwiftUI

struct WorkProgressBar: View {
    let plan: ShiftPlan
    /// 현재 시각(하루 안의 분)
    let nowMinute: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let barHeight: CGFloat = PumTokens.Space.s8

    private struct Segment: Identifiable {
        let id: Int
        let start: Int, length: Int
        let isBreak: Bool
    }

    private var segments: [Segment] {
        guard let b = plan.breakStartMinute else {
            return [.init(id: 0, start: plan.startMinute, length: plan.endMinute - plan.startMinute, isBreak: false)]
        }
        let breakEnd = b + plan.breakMinutes
        return [
            .init(id: 0, start: plan.startMinute, length: b - plan.startMinute, isBreak: false),
            .init(id: 1, start: b, length: plan.breakMinutes, isBreak: true),
            .init(id: 2, start: breakEnd, length: plan.endMinute - breakEnd, isBreak: false),
        ]
    }

    var body: some View {
        let total = CGFloat(max(1, plan.endMinute - plan.startMinute))
        VStack(spacing: PumTokens.Space.s8) {
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: PumLayout.timelineGap) {
                    ForEach(segments) { seg in
                        segmentView(seg, width: w * CGFloat(seg.length) / total)
                    }
                }
            }
            .frame(height: barHeight)
            labels
        }
        // M7: 값이 바뀔 때만. 동작 줄이기면 즉시
        .animation(reduceMotion ? nil : PumMotion.progress, value: nowMinute)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("예정 \(HomeFormat.clock(plan.startMinute))부터 \(HomeFormat.clock(plan.endMinute))까지, 휴게 \(plan.breakMinutes)분"))
        .accessibilityValue(Text("예정 근무의 \(Int((progress * 100).rounded()))% 지남"))
    }

    /// 예정 구간 기준 지난 비율(접근성 안내용)
    private var progress: Double {
        let total = Double(max(1, plan.endMinute - plan.startMinute))
        return min(1, max(0, Double(nowMinute - plan.startMinute) / total))
    }

    private func segmentView(_ seg: Segment, width: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
        let segWidth = max(0, width - PumLayout.timelineGap)
        let done = min(1, max(0, CGFloat(nowMinute - seg.start) / CGFloat(max(1, seg.length))))
        return shape
            .fill(seg.isBreak ? PumColor.surfaceFill : PumColor.accentSoftStrong)
            .overlay(alignment: .leading) {
                if !seg.isBreak {
                    shape.fill(PumColor.accent).frame(width: segWidth * done)
                }
            }
            .frame(width: segWidth)
    }

    @ViewBuilder
    private var labels: some View {
        let breakText = plan.breakStartMinute.map { "\(HomeFormat.clock($0)) 휴게 \(plan.breakMinutes)분" }
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                Text(HomeFormat.clock(plan.startMinute))
                Spacer(minLength: 0)
                if let breakText { Text(breakText) }
                Spacer(minLength: 0)
                Text(HomeFormat.clock(plan.endMinute))
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                HStack {
                    Text(HomeFormat.clock(plan.startMinute))
                    Spacer()
                    Text(HomeFormat.clock(plan.endMinute))
                }
                if let breakText { Text(breakText) }
            }
        }
        .pumText(.caption)
        .foregroundStyle(PumColor.textSecondary)
    }
}
