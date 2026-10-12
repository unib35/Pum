// UI-IOS-6s · REQ-095 — 만료된 초대(삭제된 사업장 · 권한 없음 · 세션 만료도 같은 틀). 탭 바 · 머리 없음.
import SwiftUI

struct AccessEndedView: View {
    let state: AccessEndedState
    var onPrimary: () -> Void = {}
    var onSecondary: () -> Void = {}

    /// 사업장 색 네모 약 48 — 15f와 같은 값, 큰 글자에서 글자와 함께 커진다
    @ScaledMetric(relativeTo: .headline) private var tile: CGFloat = 48

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s24) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 26px 700 → title2(24)
                        .accessibilityAddTraits(.isHeader)
                    Text(state.message).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary) // 14px 400
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let card = state.card { cardView(card) }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s24)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    private func cardView(_ card: AccessEndedState.Card) -> some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(card.initial).pumText(.headline, weight: .bold).foregroundStyle(.white) // 15px 700 → headline
                        .frame(width: tile, height: tile)
                        .background(PumColor.accent, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PumTokens.Space.s8) { names(card); badge(card) }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s8) { names(card); badge(card) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(PumTokens.Space.s16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(card.spokenText))
                ForEach(Array(card.rows.enumerated()), id: \.offset) { _, row in
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    rowView(row)
                }
            }
        }
    }

    private func names(_ card: AccessEndedState.Card) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(card.name).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700 → body
                Text(card.subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            Spacer(minLength: PumTokens.Space.s8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func badge(_ card: AccessEndedState.Card) -> some View {
        PumBadge(text: card.badgeText, kind: .problem)
    }

    private func rowView(_ row: AccessEndedState.Row) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(row.label)
                Spacer(minLength: 0)
                val(row.value).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(row.label)
                val(row.value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.spokenText))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400 #6B7280
    }

    private func val(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
    }

    private var actions: some View {
        VStack(spacing: PumTokens.Space.s4) {
            PumButton(title: state.primaryTitle, kind: .primary, action: onPrimary)
            PumButton(title: state.secondaryTitle, kind: .text, size: .small, action: onSecondary)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s4)
        .background(PumColor.bgApp)
    }
}

#Preview("6s") { AccessEndedView(state: .inviteExpired) }
#Preview("6s · 큰 글자") { AccessEndedView(state: .inviteExpired).dynamicTypeSize(.xxxLarge) }
