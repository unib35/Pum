// UI-IOS-1n · REQ-008 · REQ-107 · DEC-005 — 여러 사업장: 10월 내가 번 돈
// 금액 · 시간은 서버 값을 그대로 보여 준다. 카드를 누르면 그 사업장 급여(1l)로(연결은 후속).
import SwiftUI

struct MultiWorkplacePayView: View {
    var record: MultiWorkplaceRecord = .sample
    var onWorkplaceFilter: () -> Void = {}
    var onEntry: (MultiWorkplaceEntry) -> Void = { _ in }

    @State private var tab = "pay"
    @Environment(\.dynamicTypeSize) private var typeSize

    /// 사업장 색 네모(목업 약 44×44) — 토큰에 없어 이름을 붙임(DEC-005)
    private let tileSize: CGFloat = 44

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s14) {
                header
                summaryCard
                VStack(spacing: PumTokens.Space.s10) {
                    ForEach(record.entries) { entryCard($0) }
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s12)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
            Text("급여").pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PumTokens.Space.s8)
            MultiWorkplaceAllChip(action: onWorkplaceFilter)
        }
    }

    private var summaryCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(record.titleText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                // 목업 실측 약 40px 700 → hero 32(52보다 가까운 단계, DEC-005), 「원」 20px 600 → title3
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s2) {
                    Text(record.totalText).pumText(.hero).foregroundStyle(PumColor.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text("원").pumText(.title3, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                }
                .padding(.top, PumTokens.Space.s6)
                MultiWorkplaceBar(record: record)
                    .padding(.top, PumTokens.Space.s14)
                footer {
                    Text(record.totalWorkText).pumText(.caption, weight: .regular)
                    if !typeSize.isAccessibilitySize { Spacer(minLength: PumTokens.Space.s8) }
                    Text(record.countText).pumText(.caption, weight: .regular)
                }
                .foregroundStyle(PumColor.textSecondary)
                .padding(.top, PumTokens.Space.s8)
            }
            .padding(PumTokens.Space.s18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(record.summaryAccessibilityText))
        }
    }

    /// 아래 한 줄: 넓으면 가로, 큰 글자면 세로
    private var footer: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8))
    }

    private func entryCard(_ e: MultiWorkplaceEntry) -> some View {
        let big = typeSize.isAccessibilitySize
        let layout = big
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: PumTokens.Space.s14))
        return Button { onEntry(e) } label: {
            PumCard {
                layout {
                    HStack(spacing: PumTokens.Space.s14) {
                        Text(e.initial).pumText(.callout, weight: .bold).foregroundStyle(.white) // 15px 700
                            .frame(width: tileSize, height: tileSize)
                            .background(e.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            Text(e.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                            Text(e.detailText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: big ? .leading : .trailing, spacing: PumTokens.Space.s4) {
                        Text(e.amountText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        PumBadge(text: e.status.text, kind: e.badgeKind)
                    }
                }
                                .padding(PumTokens.Space.s16)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(e.accessibilityText))
    }
}

#Preview("1n") { MultiWorkplacePayView() }
#Preview("1n · 큰 글자") { MultiWorkplacePayView().dynamicTypeSize(.accessibility2) }
