// UI-IOS-20b · 20c · 20d — 직접 등록 단계 막대(3칸, 지난 단계까지 먹색). 세 화면이 같이 쓴다.
import SwiftUI

struct DirectRegisterStepBar: View {
    nonisolated static let stepCount = 3
    /// 원문 3 근사
    private static let barHeight: CGFloat = 3

    let current: Int

    nonisolated static func readout(current: Int) -> String { "\(stepCount)단계 중 \(current)단계" }

    var body: some View {
        HStack(spacing: PumTokens.Space.s4) {
            ForEach(1...Self.stepCount, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? PumColor.surfaceInverse : PumTokens.ColorToken.gray200)
                    .frame(height: Self.barHeight)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad + PumTokens.Space.s4) // 원문 바깥 20 + 안쪽 4
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.readout(current: current)))
    }
}
