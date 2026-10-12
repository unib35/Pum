// UI-IOS-6m · REQ-096 — 도움말 · 고객지원(탭 바 없음). 검색어만 화면 상태, 「검색」 키에서만 onSearch.
import SwiftUI

struct HelpCenterView: View {
    var state: HelpCenterState = .sample
    var onBack: () -> Void = {}
    var onSearch: (String) -> Void = { _ in }
    var onOpenTopic: (String) -> Void = { _ in }
    var onOpenFaq: (String) -> Void = { _ in }
    var onContact: () -> Void = {}
    /// 화면 · 기기 정보 첨부는 호출한 쪽 몫 — 화면은 모으지 않는다
    var onReportBug: () -> Void = {}
    var onOpenStatus: () -> Void = {}

    @State private var query = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: HelpCenterState.headerTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    searchField
                    topicGrid
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        PumSectionHeader(title: HelpCenterState.faqHeader)
                        PumCard {
                            ForEach(Array(state.faqs.enumerated()), id: \.element.id) { i, f in
                                faqRow(f, isLast: i == state.faqs.count - 1)
                            }
                        }
                    }
                    PumCard {
                        linkRow(state.contact, action: onContact, isLast: false)
                        linkRow(state.bugReport, action: onReportBug, isLast: false)
                        statusRow
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    // MARK: 검색

    private var searchField: some View {
        HStack(spacing: PumTokens.Space.s10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: PumLayout.navIcon, weight: .regular))
                .foregroundStyle(PumColor.textSecondary)
                .accessibilityHidden(true)
            TextField("", text: $query, prompt: Text(HelpCenterState.searchPlaceholder).foregroundStyle(PumColor.textTertiary))
                .pumText(.body, weight: .regular)
                .foregroundStyle(PumColor.textPrimary)
                .submitLabel(.search)
                .onSubmit { let q = query.trimmingCharacters(in: .whitespaces); if !q.isEmpty { onSearch(q) } } // 한글 조합 중 글자마다 보내지 않게 「검색」을 누를 때만
                .accessibilityLabel(Text(HelpCenterState.searchPlaceholder))
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(minHeight: PumTokens.Size.tapMin)
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .pumRing(.hairline, cornerRadius: PumTokens.Radius.lg)
    }

    // MARK: 주제 카드

    /// 2열(접근성 크기에서는 1열). 한 줄의 두 카드는 높이를 맞춘다
    private var topicGrid: some View {
        let perRow = typeSize.isAccessibilitySize ? 1 : 2
        let rows = stride(from: 0, to: state.topics.count, by: perRow).map {
            Array(state.topics[$0..<min($0 + perRow, state.topics.count)])
        }
        return VStack(spacing: PumTokens.Space.s8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: PumTokens.Space.s8) {
                    ForEach(row) { topicCard($0) }
                    if row.count < perRow { Color.clear.frame(maxWidth: .infinity) }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func topicCard(_ t: HelpTopic) -> some View {
        Button { onOpenTopic(t.id) } label: {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(t.title).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(t.detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, PumTokens.Space.s14)
            .padding(.vertical, PumTokens.Space.s12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
            .pumRing(.hairline, cornerRadius: PumTokens.Radius.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.topicAccessibility(t)))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 행

    private func faqRow(_ f: HelpFaq, isLast: Bool) -> some View {
        Button { onOpenFaq(f.id) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                Text(f.title).pumText(.body, weight: .medium).foregroundStyle(PumColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                chevron
            }
            .rowFrame(isLast: isLast)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(f.title))
        .accessibilityAddTraits(.isButton)
    }

    private func linkRow(_ r: HelpContactRow, action: @escaping () -> Void, isLast: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(r.title).pumText(.body, weight: .medium).foregroundStyle(PumColor.textPrimary)
                    Text(r.detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                chevron
            }
            .rowFrame(isLast: isLast)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.rowAccessibility(r)))
        .accessibilityAddTraits(.isButton)
    }

    private var statusRow: some View {
        Button(action: onOpenStatus) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(HelpCenterState.statusTitle).pumText(.body, weight: .medium).foregroundStyle(PumColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    statusValue
                    chevron
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        Text(HelpCenterState.statusTitle).pumText(.body, weight: .medium)
                            .foregroundStyle(PumColor.textPrimary)
                        statusValue
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
            }
            .rowFrame(isLast: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.statusAccessibility))
        .accessibilityAddTraits(.isButton)
    }

    private var statusValue: some View {
        let color = statusColor(state.status.level)
        return HStack(spacing: PumTokens.Space.s6) {
            Circle().fill(color).frame(width: PumTokens.Space.s6, height: PumTokens.Space.s6)
                .accessibilityHidden(true)
            Text(state.status.text).pumText(.footnote, weight: .semibold).foregroundStyle(color)
                .multilineTextAlignment(.leading)
        }
    }

    private func statusColor(_ l: ServiceStatusLevel) -> Color {
        switch l {
        case .normal: PumColor.statusDone
        case .degraded: PumColor.statusAttention
        case .outage: PumColor.statusDanger
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }
}

private extension View {
    func rowFrame(isLast: Bool) -> some View {
        self.padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
            }
    }
}

#Preview("6m") { HelpCenterView() }
#Preview("6m · XXXL") { HelpCenterView().dynamicTypeSize(.xxxLarge) }
#Preview("6m · 접근성") { HelpCenterView().dynamicTypeSize(.accessibility2) }
