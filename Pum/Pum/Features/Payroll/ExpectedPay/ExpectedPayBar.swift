// UI-IOS-1l — 급여 구성 막대(기본급 · 주휴 · 기타). 폭은 서버가 준 금액의 비율.
import SwiftUI

struct ExpectedPayBar: View {
    let record: ExpectedPayRecord

    /// 디자인 1l 막대 높이 약 26 — 토큰에 없어 이름을 붙임(DEC-005)
    static let barHeight: CGFloat = 26
    /// 조각 색: 기본급 statusDone, 주휴 green-300, 기타 green-50(연한 초록)
    static let colors: [Color] = [PumColor.statusDone, PumTokens.ColorToken.green300, PumTokens.ColorToken.green50]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    Rectangle().fill(Self.colors[i]).frame(width: geo.size.width * record.barFraction(i))
                }
            }
        }
        .frame(height: Self.barHeight)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.barAccessibilityText))
    }
}

/// 범례: ■ 기본급 … · ■ 주휴 … · ■ 기타 … 다음 줄 □ 공제 −…
struct ExpectedPayLegend: View {
    let record: ExpectedPayRecord

    /// 범례 네모 한 변(목업 약 8) — 토큰 간격 단계를 크기로 재사용
    private let swatch: CGFloat = PumTokens.Space.s8
    /// 공제 네모 테두리 두께
    private let outlineWidth: CGFloat = 1.5
    /// 먹색 위 공제 글자 — red-50(연한 빨강). 어두운 바탕에서 읽히는 빨강 토큰이 이것뿐
    static let deductionTint = PumTokens.ColorToken.red50

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            ExpectedPayFlowRow(spacing: PumTokens.Space.s12) {
                item(color: ExpectedPayBar.colors[0], "기본급 \(PumFormat.amount(record.basePay))")
                item(color: ExpectedPayBar.colors[1], "주휴 \(PumFormat.amount(record.holidayPay))")
                item(color: ExpectedPayBar.colors[2], "기타 \(PumFormat.amount(record.otherPay))")
            }
            HStack(spacing: PumTokens.Space.s6) {
                RoundedRectangle(cornerRadius: PumTokens.Space.s2, style: .continuous)
                    .stroke(Self.deductionTint, lineWidth: outlineWidth)
                    .frame(width: swatch, height: swatch)
                Text("공제 \(record.deductionText)").pumText(.caption, weight: .regular)
                    .foregroundStyle(Self.deductionTint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true) // 구성 막대가 같은 내용을 한 문장으로 읽는다
    }

    private func item(color: Color, _ text: String) -> some View {
        HStack(spacing: PumTokens.Space.s6) {
            RoundedRectangle(cornerRadius: PumTokens.Space.s2, style: .continuous).fill(color)
                .frame(width: swatch, height: swatch)
            Text(text).pumText(.caption, weight: .regular).foregroundStyle(.white)
        }
    }
}

/// 한 줄에 다 안 들어가면 다음 줄로 넘기는 가로 배치
struct ExpectedPayFlowRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = arrange(width: bounds.width, subviews: subviews)
        for (i, p) in r.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing / 2; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + spacing
            maxX = max(maxX, x - spacing)
            rowH = max(rowH, sz.height)
        }
        return (CGSize(width: maxX, height: y + rowH), origins)
    }
}
