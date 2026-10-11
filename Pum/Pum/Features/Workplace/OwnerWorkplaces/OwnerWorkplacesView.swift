// UI-IOS-1w · REQ-008 · DEC-005 — 사장님 「사업장」 탭: 전체 사업장 통합 뷰
// 금액 · 인원 · 건수 · D-7 · 막대 비율은 서버 값 그대로. 카드 · 배지 · 추가는 바깥에서 연결(클로저).
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만 이름을 붙임(DEC-005)
private enum OwnerWorkplacesLayout {
    /// 요약 막대 높이(목업 약 10) — 가장 가까운 간격 단계 s10
    static let summaryBarHeight: CGFloat = PumTokens.Space.s10
    /// 카드 막대 높이(목업 약 8) — s8
    static let cardBarHeight: CGFloat = PumTokens.Space.s8
    /// 막대 두 구간 사이 틈(목업 약 2) — s2
    static let barGap: CGFloat = PumTokens.Space.s2
    /// 먹색 위 안쪽 구분선: 흰 10%(원문). 먹색 위 hairline 토큰이 없어 화면 안에서만 씀
    static let inverseLine = Color.white.opacity(0.1)
    /// 점선 모양: 선 6 · 틈 4, 두께 1(hairline 두께)
    static let dash = StrokeStyle(lineWidth: 1, dash: [6, 4])
    /// 점선 색 — hairline(6%)은 점선으로는 안 보여 같은 회색 계열 gray-300(배지 종료 테두리와 같은 색)
    static let dashColor = PumTokens.ColorToken.gray300
    /// 추가 버튼 높이(목업 약 50) — 버튼 높이 54에서 간격 단계 s4만큼 뺌
    static let addButtonHeight: CGFloat = PumTokens.Size.buttonH - PumTokens.Space.s4
}

struct OwnerWorkplacesView: View {
    var record: OwnerWorkplacesRecord = .sample
    var onEntry: (OwnerWorkplaceEntry) -> Void = { _ in }
    var onAdd: () -> Void = {}

    @State private var tab = "store"
    @Environment(\.dynamicTypeSize) private var typeSize
    /// 사업장 색 네모(목업 약 44) — 터치 최소 크기와 같은 값
    @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = PumTokens.Size.tapMin

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s16) {
                header
                summaryCard
                VStack(spacing: PumTokens.Space.s12) {
                    ForEach(record.entries) { entryCard($0) }
                }
                addButton
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: 0), selection: $tab)
        }
    }

    // MARK: 머리

    private var header: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
            Text("전체 사업장").pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PumTokens.Space.s8)
            PumIconButton(systemImage: "plus", label: "사업장 추가", action: onAdd)
        }
    }

    // MARK: 먹색 요약 카드

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            titleRow
            // 목업 34px 700 → hero 32(가장 가까운 단계), 「원」도 같은 크기
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s2) {
                Text(record.totalText).lineLimit(1).minimumScaleFactor(0.5)
                Text("원")
            }
            .pumText(.hero).foregroundStyle(.white)
            OwnerWorkplacesSummaryBar(record: record)
            Rectangle().fill(OwnerWorkplacesLayout.inverseLine).frame(height: 1)
            statsRow
        }
        .padding(PumTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.summaryAccessibilityText))
    }

    private var titleRow: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8))
        return layout {
            Text(record.titleText).pumText(.footnote, weight: .medium) // 13px 500
            if !typeSize.isAccessibilitySize { Spacer(minLength: PumTokens.Space.s8) }
            Text(record.countText).pumText(.caption, weight: .regular) // 12px
        }
        .foregroundStyle(PumColor.textOnInverseSecondary) // 원문 흰 60% → 공통 70%(충돌 #24)
    }

    /// 3칸: 넓으면 가로, 큰 글자면 세로
    private var statsRow: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: PumTokens.Space.s8))
        return layout {
            stat("지금 근무 중", record.workingText, .white)
            stat("확인 필요", record.attentionText, PumColor.statusAttentionLine) // 주황 → amber-200(1ak와 같음)
            stat("급여 정산", record.dDayText, .white)
        }
    }

    private func stat(_ label: String, _ value: String, _ valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2, weight: .regular) // 11px
                .foregroundStyle(PumColor.textOnInverseSecondary) // 흰 55% → 70%
            Text(value).pumText(.headline, weight: .bold).foregroundStyle(valueColor) // 18px 700
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 사업장 카드

    private func entryCard(_ e: OwnerWorkplaceEntry) -> some View {
        let big = typeSize.isAccessibilitySize
        let amountLayout = big
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8))
        return PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                Button { onEntry(e) } label: {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                        HStack(spacing: PumTokens.Space.s12) {
                            Text(e.initial).pumText(.body, weight: .bold).foregroundStyle(.white) // 15px 700
                                .frame(width: tileSize, height: tileSize)
                                .background(e.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                                Text(e.name).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700
                                Text(e.staffText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                                .foregroundStyle(PumColor.textDisabled)
                        }
                        amountLayout {
                            Text("예상 인건비").pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                            if !big { Spacer(minLength: PumTokens.Space.s8) }
                            Text("\(e.amountText)원").pumText(.title3).foregroundStyle(PumColor.textPrimary) // 20px 700
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        OwnerWorkplacesCardBar(fraction: e.confirmedFraction)
                    }
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(e.accessibilityText))
                .accessibilityAddTraits(.isButton)

                if !e.badges.isEmpty {
                    OwnerWorkplacesFlow(hSpacing: PumTokens.Space.s6, vSpacing: PumTokens.Space.s6) {
                        // 원문: 배지는 요약 표시(촘촘한 한 줄) — 따로 누르지 않고 카드 위쪽 누름이 사업장으로 이동.
                        // 내용은 카드 VoiceOver 문장에 들어 있다
                        ForEach(e.badges) { b in
                            PumBadge(text: b.text, kind: b.isAttention ? .attention : .waiting)
                        }
                    }
                    .accessibilityHidden(true)
                }
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: 사업장 추가

    private var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: PumTokens.Space.s6) {
                Image(systemName: "plus").font(.footnote.weight(.semibold))
                Text("사업장 추가").pumText(.body, weight: .semibold) // 15px 600
            }
            .foregroundStyle(PumColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: OwnerWorkplacesLayout.addButtonHeight)
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous)
                    .strokeBorder(OwnerWorkplacesLayout.dashColor, style: OwnerWorkplacesLayout.dash)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("사업장 추가"))
    }
}

// MARK: - 막대

/// 요약 막대: 앞 = 확정(green-300), 뒤 = 남은 예정(statusDone). 폭은 서버가 준 두 값의 비율
struct OwnerWorkplacesSummaryBar: View {
    let record: OwnerWorkplacesRecord

    var body: some View {
        GeometryReader { geo in
            let usable = max(0, geo.size.width - OwnerWorkplacesLayout.barGap)
            // 두 구간 + 틈 하나(Spacer 없이 — 틈이 두 번 들어가 넘치지 않게)
            HStack(spacing: OwnerWorkplacesLayout.barGap) {
                Rectangle().fill(PumTokens.ColorToken.green300).frame(width: usable * record.barFraction(0))
                Rectangle().fill(PumColor.statusDone).frame(width: usable * record.barFraction(1))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: OwnerWorkplacesLayout.summaryBarHeight)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.barAccessibilityText))
    }
}

/// 카드 막대: 바탕 surfaceFill, 채움 statusDone(확정 비율)
struct OwnerWorkplacesCardBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(PumColor.surfaceFill)
                Rectangle().fill(PumColor.statusDone).frame(width: geo.size.width * min(1, max(0, fraction)))
            }
        }
        .frame(height: OwnerWorkplacesLayout.cardBarHeight)
        .clipShape(Capsule())
        .accessibilityHidden(true) // 장식(카드 한 문장 안에 금액이 있음)
    }
}

/// 한 줄에 다 안 들어가면 다음 줄로 넘기는 가로 배치
struct OwnerWorkplacesFlow: Layout {
    var hSpacing: CGFloat
    var vSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (i, p) in arrange(width: bounds.width, subviews: subviews).origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + vSpacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + hSpacing
            maxX = max(maxX, x - hSpacing)
            rowH = max(rowH, sz.height)
        }
        return (CGSize(width: maxX, height: y + rowH), origins)
    }
}

#Preview("1w") { OwnerWorkplacesView() }
#Preview("1w · 큰 글자") { OwnerWorkplacesView().dynamicTypeSize(.accessibility2) }
