// UI-IOS-6d · REQ-090 — 내 동의 내역 (탭 바 없음).
// 토글은 서버 값을 Binding으로 읽고 바꾸면 onToggleOptional만 부른다(@State 복사 없음).
// 철회(끄기) 확인 창은 원문에 없어 클로저만 둔다.
import SwiftUI

struct ConsentsView: View {
    let state: ConsentsState
    var onBack: () -> Void = {}
    var onOpenChange: () -> Void = {}
    var onOpen: (String) -> Void = { _ in }
    var onToggleOptional: (String, Bool) -> Void = { _, _ in }

    /// 행 위아래 안쪽 — 원문 11 → 토큰 12(DEC-009)
    private let rowPadY = PumTokens.Size.rowPadY
    /// 제목–안내 글자 — 원문 3 → 토큰 2
    private let detailGap = PumTokens.Space.s2

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: ConsentsState.headerTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    if let change = state.pendingChange { changeCard(change) }
                    rowsCard(state.consents)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 제목–카드 8(원문 14 − 6)
                        PumSectionHeader(title: ConsentsState.thirdPartyHeader)
                        rowsCard(state.thirdParties)
                    }
                    .padding(.top, PumTokens.Space.s2)
                    Text(ConsentsState.footnote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s14)
            }
        }
        .background(PumColor.bgApp)
    }

    // MARK: 변경 예정

    private func changeCard(_ change: ConsentPendingChange) -> some View {
        PumCard(attention: true) {
            Button(action: onOpenChange) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PumTokens.Space.s10) {
                        changeText(change).frame(maxWidth: .infinity, alignment: .leading)
                        confirmLabel
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        changeText(change)
                        confirmLabel
                    }
                }
                .padding(.horizontal, PumTokens.Space.s16).padding(.vertical, PumTokens.Space.s12)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(change.spoken))
            .accessibilityAddTraits(.isButton)
        }
    }

    private func changeText(_ change: ConsentPendingChange) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { changeBadge; effective(change) }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { changeBadge; effective(change) }
            }
            Text(change.summary).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                .multilineTextAlignment(.leading)
        }
    }

    private var changeBadge: some View { PumBadge(text: ConsentsState.changeBadge, kind: .attention) }

    private func effective(_ change: ConsentPendingChange) -> some View {
        Text(change.effectiveText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }

    private var confirmLabel: some View {
        Text("\(ConsentsState.changeConfirm) ›").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.accent)
    }

    // MARK: 행

    private func rowsCard(_ rows: [ConsentRow]) -> some View {
        PumCard {
            ForEach(rows) { row in
                let isLast = row.id == rows.last?.id
                if row.hasToggle { toggleRow(row, isLast: isLast) } else { openRow(row, isLast: isLast) }
            }
        }
    }

    private func openRow(_ row: ConsentRow, isLast: Bool) -> some View {
        Button { onOpen(row.id) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                rowText(row).frame(maxWidth: .infinity, alignment: .leading)
                chevron
            }
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { if !isLast { hairline } }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.spoken))
        .accessibilityAddTraits(.isButton)
    }

    private func toggleRow(_ row: ConsentRow, isLast: Bool) -> some View {
        Toggle(isOn: Binding(get: { row.isOn }, set: { onToggleOptional(row.id, $0) })) {
            rowText(row)
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) { if !isLast { hairline } }
        .accessibilityLabel(Text(row.spoken))
    }

    private func rowText(_ row: ConsentRow) -> some View {
        VStack(alignment: .leading, spacing: detailGap) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s6) { title(row); badge(row) }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { title(row); badge(row) }
            }
            Text(row.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    private func title(_ row: ConsentRow) -> some View {
        Text(row.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.leading)
    }

    /// 필수 = 회색(waiting), 선택 = 연파랑(active)
    private func badge(_ row: ConsentRow) -> some View {
        PumBadge(text: row.badgeText, kind: row.kind == .required ? .waiting : .active)
    }

    private var hairline: some View { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.body.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }
}

#Preview("동의 내역 6d") { ConsentsView(state: .sample) }
#Preview("동의 내역 6d · 큰 글자") { ConsentsView(state: .sample).dynamicTypeSize(.xxxLarge) }
