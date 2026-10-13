// UI-IOS-6k · REQ-061 — 내 문서(직원). 탭 바 5개(내 정보 선택, 충돌 #9) · 종류 칩으로 거르기 · 확인 필요 카드 → 연도별 목록.
import SwiftUI

struct DocumentBoxView: View {
    let state: DocumentBoxState
    var onPickWorkplace: () -> Void = {}
    var onOpen: (String) -> Void = { _ in }
    var onIssue: (String) -> Void = { _ in }

    @State private var filter: DocumentFilter = .all
    @State private var tab = "me"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tabs: [PumTabItem] {
        [
            .init(id: "home", title: "홈", systemImage: "house"),
            .init(id: "work", title: "근무", systemImage: "calendar"),
            .init(id: "news", title: "소식", systemImage: "bell"),
            .init(id: "pay", title: "급여", systemImage: "wonsign.circle"),
            .init(id: "me", title: "내 정보", systemImage: "person"),
        ]
    }

    var body: some View {
        let attention = state.attention(under: filter)
        let years = state.years(under: filter)
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) { // 원문 gap 12
                header
                filterChips
                if !attention.isEmpty {
                    VStack(spacing: PumTokens.Space.s6) { // 원문: gap 12 − 6
                        PumSectionHeader(title: DocumentBoxState.attentionHeader, attention: true)
                            .padding(.top, PumTokens.Space.s2) // 원문 padding 2 4 0
                        PumCard(attention: true) {
                            ForEach(attention) { item in
                                DocumentRow(item: item, isLast: item.id == attention.last?.id,
                                            onOpen: onOpen, onIssue: onIssue)
                            }
                        }
                    }
                }
                ForEach(years) { group in
                    VStack(spacing: PumTokens.Space.s6) {
                        PumSectionHeader(title: group.year)
                            .padding(.top, PumTokens.Space.s2)
                        PumCard {
                            ForEach(group.items) { item in
                                DocumentRow(item: item, isLast: item.id == group.items.last?.id,
                                            onOpen: onOpen, onIssue: onIssue)
                            }
                        }
                    }
                }
                Text(DocumentBoxState.footnote)
                    .pumText(.caption)
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, PumTokens.Space.s4)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
            .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: filter)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: tabs, selection: $tab)
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                title
                Spacer(minLength: PumTokens.Space.s8)
                workplaceChip
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                title
                workplaceChip
            }
        }
    }

    private var title: some View {
        Text(DocumentBoxState.headerTitle).pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    /// 원문: 타일 없이 글자 + 화살표만 있는 흰 칩(공통 PumWorkplaceChip은 타일이 있어 쓰지 않음)
    private var workplaceChip: some View {
        Button(action: onPickWorkplace) {
            HStack(spacing: PumTokens.Space.s6) {
                Text(DocumentBoxState.workplaceFilterTitle).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PumColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PumTokens.Space.s14) // 원문 padding 8 14
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.surfaceCard, in: Capsule())
            .pumRing(.hairline, cornerRadius: PumTokens.Size.tapMin / 2)
            .padding(.vertical, -PumTokens.Space.s6) // 보이는 높이 약 32, 누름은 44 유지
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("사업장: \(DocumentBoxState.workplaceFilterTitle)"))
        .accessibilityHint(Text("사업장을 바꿔요"))
    }

    private var filterChips: some View {
        let all = DocumentFilter.allCases
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PumTokens.Space.s6) {
                ForEach(Array(all.enumerated()), id: \.element) { index, item in
                    PumChoicePill(title: item.title, isOn: item == filter, offStyle: .outlined,
                                  position: (index, all.count)) { filter = item }
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
        }
        .padding(.horizontal, -PumTokens.Size.screenPad) // 가장자리까지 스크롤
    }
}

// MARK: - 문서 행

private struct DocumentRow: View {
    let item: DocumentItem
    let isLast: Bool
    let onOpen: (String) -> Void
    let onIssue: (String) -> Void
    @ScaledMetric private var tile = PumLayout.avatar

    var body: some View {
        Group {
            if item.status == .issuable {
                rowContent.accessibilityElement(children: .contain) // 행은 누르지 않고 「발급」 버튼만
            } else {
                Button { onOpen(item.id) } label: { rowContent }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(item.accessibilityText))
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
    }

    private var rowContent: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                iconTile
                texts.frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) { // 넘치면 상태를 글자 아래로
                iconTile
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    texts
                    trailing
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .contentShape(Rectangle())
    }

    private var iconTile: some View {
        Image(systemName: "doc")
            .font(.callout)
            .foregroundStyle(PumColor.textPrimary)
            .frame(width: tile, height: tile)
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .accessibilityHidden(true)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(item.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(item.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder private var trailing: some View {
        if let kind = item.status.badgeKind {
            PumBadge(text: item.statusText, kind: kind)
        } else {
            Button { onIssue(item.id) } label: {
                Text(item.statusText).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.accent)
                    .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .trailing) // 원문처럼 배지 끝선에 맞춤
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(item.title) 발급"))
        }
    }
}

#Preview("내 문서 6k") { DocumentBoxView(state: .sample) }
#Preview("내 문서 6k · 큰 글자") { DocumentBoxView(state: .sample).dynamicTypeSize(.xxxLarge) }
