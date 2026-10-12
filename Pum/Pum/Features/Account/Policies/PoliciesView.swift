// UI-IOS-6c · REQ-090 — 약관 및 정책 (탭 바 없음). 개인정보처리방침은 앱 어디서든 두 번 안에.
import SwiftUI

struct PoliciesView: View {
    let state: PoliciesState
    var onBack: () -> Void = {}
    var onOpenChange: () -> Void = {}
    var onOpen: (String) -> Void = { _ in }
    var onOpenConsents: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: PoliciesState.headerTitle, onBack: onBack)
                .padding(.top, PumTokens.Space.s8)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    if let notice = state.notice { noticeBand(notice) }
                    PumCard {
                        ForEach(state.rows) { row in
                            policyRow(row, isLast: row.id == state.rows.last?.id)
                        }
                    }
                    footer
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    // MARK: 변경 예고 띠

    private func noticeBand(_ n: PolicyChangeNotice) -> some View {
        Button(action: onOpenChange) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    noticeText(n)
                    Spacer(minLength: PumTokens.Space.s8)
                    noticeAction
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    noticeText(n)
                    noticeAction
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Space.s16).padding(.vertical, PumTokens.Space.s12)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.accentSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.noticeAccessibility(n)))
        .accessibilityAddTraits(.isButton)
    }

    /// 13px: 약관 이름만 굵게. 원문 진한 파랑(#1F3FB0)은 토큰에 없어 accent 사용
    private func noticeText(_ n: PolicyChangeNotice) -> some View {
        var name = AttributedString(n.documentName)
        name.font = PumFont.font(size: PumTokens.FontToken.footnote.size, weight: .bold, relativeTo: .footnote)
        var rest = AttributedString(PoliciesState.noticeMiddle(n.documentName) + n.effectiveDate + PoliciesState.noticeTail)
        name.foregroundColor = PumColor.accent
        rest.foregroundColor = PumColor.accent
        return Text(name + rest)
            .pumText(.footnote, weight: .regular)
            .multilineTextAlignment(.leading)
    }

    private var noticeAction: some View {
        Text(PoliciesState.noticeAction + " ›").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.accent)
    }

    // MARK: 행

    private func policyRow(_ row: PolicyRow, isLast: Bool) -> some View {
        Button { onOpen(row.id) } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    titleBlock(row)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let v = row.value { valueText(v) }
                    chevron
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        titleBlock(row)
                        if let v = row.value { valueText(v).multilineTextAlignment(.leading) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { if !isLast { hairline } }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.rowAccessibility(row)))
        .accessibilityAddTraits(.isButton)
    }

    private func titleBlock(_ row: PolicyRow) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(row.title)
                .pumText(.body, weight: row.isEmphasized ? .bold : .medium)
                .foregroundStyle(PumColor.textPrimary)
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
        Image(systemName: "chevron.right").font(.body.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    private var hairline: some View { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }

    // MARK: 안내

    /// 12px 보조색, 「내 동의 내역」만 굵게. 누르면 6d(원문에 링크 표시는 없어 버튼 traits만)
    private var footer: some View {
        var lead = AttributedString(PoliciesState.footerLead)
        var link = AttributedString(PoliciesState.footerLink)
        var tail = AttributedString(PoliciesState.footerTail)
        link.font = PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption)
        lead.foregroundColor = PumColor.textSecondary
        link.foregroundColor = PumColor.textSecondary
        tail.foregroundColor = PumColor.textSecondary
        return Button(action: onOpenConsents) {
            Text(lead + link + tail)
                .pumText(.caption, weight: .regular)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, PumTokens.Space.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(PoliciesState.footerText))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("약관 6c") { PoliciesView(state: .sample) }
#Preview("약관 6c · 예고 없음") { PoliciesView(state: .sampleNoNotice) }
#Preview("약관 6c · 큰 글자") { PoliciesView(state: .sample).dynamicTypeSize(.xxxLarge) }
