// UI-IOS-1n — 사업장별 막대 · 「전체 사업장」 먹색 칩. 막대 폭은 서버가 준 금액의 비율.
import SwiftUI

struct MultiWorkplaceBar: View {
    let record: MultiWorkplaceRecord

    /// 디자인 1n 막대 높이 약 12 — 토큰에 없어 이름을 붙임(DEC-005)
    static let barHeight: CGFloat = 12
    /// 조각 사이 틈(목업 약 2) — space-2
    static let gap: CGFloat = PumTokens.Space.s2

    var body: some View {
        GeometryReader { geo in
            let n = record.entries.count
            let usable = max(0, geo.size.width - Self.gap * CGFloat(max(0, n - 1)))
            HStack(spacing: Self.gap) {
                ForEach(Array(record.entries.enumerated()), id: \.element.id) { i, e in
                    Rectangle().fill(e.tileColor).frame(width: usable * record.barFraction(i))
                }
            }
        }
        .frame(height: Self.barHeight)
        .clipShape(Capsule()) // 양 끝 둥근 모서리
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.barAccessibilityText))
    }
}

/// 먹색 「전체 사업장」 칩: 사업장 색 네모 3개가 겹쳐 쌓인 모양 + 이름 + 꺾쇠
struct MultiWorkplaceAllChip: View {
    var title = "전체 사업장"
    /// 사업장 색(C7): 파랑 · 갈색 · 남색 — 갈색 · 남색은 토큰 밖(충돌 #20)이라 PumAvatarPalette 값을 쓴다
    var colors: [Color] = PumAvatarPalette.stores
    let action: () -> Void

    /// 목업 네모 약 20×24 — 토큰에 없어 이름을 붙임(DEC-005)
    private let tileWidth: CGFloat = 20
    private let tileHeight: CGFloat = 24
    /// 겹침 정도(목업 살짝 겹침) — space-6
    private let overlap: CGFloat = PumTokens.Space.s6

    var body: some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s8) {
                HStack(spacing: -overlap) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { _, c in
                        RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous).fill(c)
                            .frame(width: tileWidth, height: tileHeight)
                            .overlay(RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                                .strokeBorder(PumColor.surfaceInverse, lineWidth: 1))
                    }
                }
                Text(title).pumText(.footnote, weight: .semibold).foregroundStyle(.white) // 14px 600
                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.white)
            }
            .padding(.leading, PumTokens.Space.s8)
            .padding(.trailing, PumTokens.Space.s12)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.surfaceInverse, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("사업장: \(title)"))
        .accessibilityHint(Text("사업장을 바꿔요"))
    }
}
