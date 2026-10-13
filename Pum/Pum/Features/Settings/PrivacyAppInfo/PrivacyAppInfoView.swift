// UI-IOS-6o · REQ-090 — 개인정보 · 앱 정보 (탭 바 없음). 앱 버전 행은 누르지 않는다.
import SwiftUI

struct PrivacyAppInfoView: View {
    let state: PrivacyAppInfoState
    var onBack: () -> Void = {}
    var onOpen: (String) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: PrivacyAppInfoState.headerTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    ForEach(state.sections) { section in
                        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                            PumSectionHeader(title: section.title).padding(.top, PumTokens.Space.s2)
                            PumCard {
                                ForEach(section.rows) { row in
                                    rowView(row, isLast: row.id == section.rows.last?.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    @ViewBuilder
    private func rowView(_ row: PrivacyAppInfoRow, isLast: Bool) -> some View {
        if row.isTappable {
            Button { onOpen(row.id) } label: { rowContent(row, isLast: isLast) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.rowAccessibility(row)))
                .accessibilityAddTraits(.isButton)
        } else {
            rowContent(row, isLast: isLast)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.rowAccessibility(row)))
        }
    }

    private func rowContent(_ row: PrivacyAppInfoRow, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                titleBlock(row).frame(maxWidth: .infinity, alignment: .leading)
                if let v = row.value { valueText(v) }
                if row.isTappable { chevron }
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    titleBlock(row)
                    if let v = row.value { valueText(v).multilineTextAlignment(.leading) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if row.isTappable { chevron }
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) { if !isLast { hairline } }
    }

    private func titleBlock(_ row: PrivacyAppInfoRow) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(row.title)
                .pumText(.body, weight: row.isEmphasized ? .bold : .medium)
                .foregroundStyle(row.isDanger ? PumColor.statusDanger : PumColor.textPrimary)
                .multilineTextAlignment(.leading)
            if let d = row.detail {
                Text(d).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.footnote).foregroundStyle(PumColor.textSecondary).multilineTextAlignment(.trailing)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    private var hairline: some View { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
}

#Preview("개인정보 · 앱 정보 6o") { PrivacyAppInfoView(state: .sample) }
#Preview("개인정보 · 앱 정보 6o · 큰 글자") { PrivacyAppInfoView(state: .sample).dynamicTypeSize(.xxxLarge) }
