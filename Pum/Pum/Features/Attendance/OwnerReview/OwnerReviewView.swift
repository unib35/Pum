// UI-IOS-1r · REQ-026 · REQ-027 · DEC-005 — 확인 필요 근무(사장님 근무 탭): 유형별 빠른 처리
// 색: 주황 = 확인 필요, 빨강 = 기록 없음 · 거절, 파랑 = 인정. 버튼은 클로저만 받는다.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만
private enum OwnerReviewLayout {
    /// 세그먼트 「확인 필요」 옆 숫자 배지 지름(목업 18px 원 → 토큰 크기 중 가장 가까운 tapMin의 절반인 22 대신 s18)
    static let countBadge: CGFloat = PumTokens.Space.s18
    /// 사람 아바타(목업 34)
    static let avatar: CGFloat = 34
}

struct OwnerReviewView: View {
    var state: OwnerReviewState = .sample
    var onChangeFilter: (OwnerReviewFilter) -> Void = { _ in }
    var onAction: (OwnerReviewAction, OwnerReviewItem) -> Void = { _, _ in }
    @State private var tab = "work"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .callout) private var avatarSize = OwnerReviewLayout.avatar

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                ForEach(state.items) { item in card(item) }
                Text(state.autoConfirmedText)
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, PumTokens.Space.s2) // 원문 안내 글 위 2
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: state.workTabBadge), selection: $tab)
        }
    }

    // MARK: 머리 · 세그먼트

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                title
                Spacer(minLength: PumTokens.Space.s8)
                segment
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                segment
            }
        }
    }

    private var title: some View {
        // 목업 28px 700 → title1(28)
        Text("근무").pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    /// 확인 필요 · 처리됨 · 전체 — 1j 세그먼트와 같은 모양(회색 캡슐 + 흰 선택 캡슐)
    private var segment: some View {
        HStack(spacing: 0) {
            ForEach(OwnerReviewFilter.allCases, id: \.self) { f in
                let selected = f == state.filter
                Button { onChangeFilter(f) } label: {
                    HStack(spacing: PumTokens.Space.s4) {
                        Text(title(of: f)).pumText(.footnote, weight: selected ? .semibold : .medium) // 목업 13px
                            .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        if f == .needsReview {
                            Text("\(state.needsReviewCount)")
                                .pumText(.caption2, weight: .semibold) // 목업 11px 600
                                .foregroundStyle(.white)
                                .padding(.horizontal, PumTokens.Space.s4)
                                .frame(minWidth: OwnerReviewLayout.countBadge, minHeight: OwnerReviewLayout.countBadge)
                                .background(PumColor.statusAttentionDot, in: Capsule()) // amber400
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, PumTokens.Space.s12)
                    .padding(.vertical, PumTokens.Space.s6) // 원문 칸 padding 6 12
                    .background(selected ? PumColor.surfaceCard : .clear, in: Capsule())
                    // 누름 영역은 44 유지, 배치는 원문 칸 높이만
                    .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Capsule())
                    .padding(.vertical, -(PumTokens.Size.tapMin - (PumTokens.Space.s6 * 2 + PumTokens.Space.s16)) / 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(f == .needsReview ? "확인 필요 \(state.needsReviewCount)건" : f == .processed ? "\(title(of: f))건" : title(of: f)))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: Capsule())
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: state.filter)
    }

    private func title(of f: OwnerReviewFilter) -> String {
        switch f {
        case .needsReview: "확인 필요"
        case .processed: state.processedTitle
        case .all: "전체"
        }
    }

    // MARK: 카드

    private func card(_ item: OwnerReviewItem) -> some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                summary(item)
                bottom(item)
            }
            .padding(.vertical, PumTokens.Space.s14) // 원문 카드 padding 14 16
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 아바타 · 이름 · 배지 · 시간 상자 — 카드 한 문장으로 읽는다(버튼은 따로)
    private func summary(_ item: OwnerReviewItem) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s10) { // 원문 gap 10
                    person(item).frame(maxWidth: .infinity, alignment: .leading)
                    PumBadge(text: item.badgeText, kind: item.kind.badgeKind)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    person(item)
                    PumBadge(text: item.badgeText, kind: item.kind.badgeKind)
                }
            }
            if item.hasTimeBox { timeBox(item) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.accessibilitySummary))
    }

    private func person(_ item: OwnerReviewItem) -> some View {
        HStack(spacing: PumTokens.Space.s10) { // 원문 gap 10
            PumAvatar(name: item.name, colorIndex: item.colorIndex, size: avatarSize)
            Text("\(Text(item.name).pumFontBold)\(Text(" \u{00B7} \(item.dateText)").font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .medium, relativeTo: .caption)).foregroundColor(PumColor.textSecondary))")
        }
    }

    /// 회색 상자: 예정 → 실제 (실제는 유형 색: 연장 = 주황, 기록 없음 = 빨강)
    private func timeBox(_ item: OwnerReviewItem) -> some View {
        let accent = item.kind == .missingClockOut ? PumColor.statusDanger : PumColor.statusAttention
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s10) {
                planned(item)
                arrow
                actual(item, accent: accent)
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                planned(item)
                actual(item, accent: accent)
            }
        }
        .padding(.vertical, PumTokens.Space.s10)
        .padding(.horizontal, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
    }

    private func planned(_ item: OwnerReviewItem) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text("예정").pumText(.caption2).foregroundStyle(PumColor.textSecondary)
            Text(item.plannedRange ?? "").pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        }
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .pumText(.footnote)
            .foregroundStyle(PumColor.textSecondary)
            .accessibilityHidden(true)
    }

    private func actual(_ item: OwnerReviewItem, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text("실제").pumText(.caption2).foregroundStyle(accent)
            // 원문: 출근 시각은 먹색, 문제가 된 퇴근 쪽만 강조색
            Text("\(Text(item.actualLead ?? "").foregroundColor(PumColor.textPrimary))\(Text(item.actualEndText).foregroundColor(accent).fontWeight(.bold))")
                .pumText(.callout, weight: .bold) // 목업 14px 700
        }
    }

    // MARK: 설명 · 버튼

    private func bottom(_ item: OwnerReviewItem) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s10) { // 원문 설명~버튼 gap 10
                explanation(item).frame(maxWidth: .infinity, alignment: .leading)
                buttons(item)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                explanation(item)
                buttons(item)
            }
            // 접근성 큰 글자: 버튼도 세로로(카드 폭을 넘지 않게)
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                explanation(item)
                buttons(item, stacked: true)
            }
        }
    }

    private func explanation(_ item: OwnerReviewItem) -> some View {
        var t = Text(item.explanationText).foregroundColor(PumColor.textSecondary)
        if let amount = item.amount {
            t = Text("\(t)\(Text(amount.text).fontWeight(.bold).foregroundColor(PumColor.textPrimary))")
        }
        return t.pumText(.footnote) // 목업 13px
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true) // 위 카드 문장에 이미 포함
    }

    private func buttons(_ item: OwnerReviewItem, stacked: Bool = false) -> some View {
        let secondary = item.kind.secondary
        let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s8))
                             : AnyLayout(HStackLayout(spacing: PumTokens.Space.s8))
        return layout {
            PumButton(title: secondary.title, kind: secondary.kind, size: .small) { onAction(secondary.action, item) }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel(Text("\(item.name) \(secondary.title)"))
            PumButton(title: item.primaryTitle, kind: item.kind.primaryKind, size: .small) { onAction(item.kind.primaryAction, item) }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel(Text(item.primaryAccessibilityTitle))
        }
    }
}

private extension Text {
    /// 이름: 목업 15px 600 → body(15) semibold
    var pumFontBold: Text { self.font(PumFont.font(size: PumTokens.FontToken.body.size, weight: .semibold, relativeTo: .body)).foregroundColor(PumColor.textPrimary) }
}

#Preview("1r") { OwnerReviewView() }
#Preview("1r · 큰 글자") { OwnerReviewView().dynamicTypeSize(.xxxLarge) }
