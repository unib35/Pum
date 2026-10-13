// UI-IOS-10o · REQ-080 — 직원 · 퇴사 후 (하위 화면, 탭 바 없음). 읽기 전용: 열기 · 요청 클로저만.
import SwiftUI

struct AfterLeavingView: View {
    let state: AfterLeavingState
    var onBack: () -> Void
    var onOpenDocument: (AfterLeavingDocumentKind) -> Void
    /// 요청 화면 원문 없음 — 클로저만
    var onRequestCertificate: () -> Void

    init(state: AfterLeavingState = .sample,
         onBack: @escaping () -> Void = {},
         onOpenDocument: @escaping (AfterLeavingDocumentKind) -> Void = { _ in },
         onRequestCertificate: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onOpenDocument = onOpenDocument
        self.onRequestCertificate = onRequestCertificate
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.workplaceName, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    headerCard
                    section(AfterLeavingState.payTitle) { payCard }
                    section(AfterLeavingState.documentsTitle) { documentsCard }
                    certificateCard
                    Text(state.retentionNote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: title)
            content()
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled)
            .accessibilityHidden(true)
    }

    // MARK: 퇴사 카드

    private var headerCard: some View {
        PumCard {
            let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.leftTitle).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(state.periodText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    texts.frame(maxWidth: .infinity, alignment: .leading)
                    PumBadge(text: state.statusText, kind: .waiting).fixedSize()
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    texts
                    PumBadge(text: state.statusText, kind: .waiting)
                }
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.headerSpoken))
        }
    }

    // MARK: 받을 돈

    private var payCard: some View {
        PumCard {
            ForEach(Array(state.payItems.enumerated()), id: \.element.id) { i, item in
                if i > 0 { divider }
                payRow(item)
            }
        }
    }

    private func payRow(_ item: AfterLeavingPayItem) -> some View {
        let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(item.title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            Text(item.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        // 금액이 없으면 서버가 준 상태 글자를 회색으로
        let value = Text(item.amount.text).pumText(.callout, weight: .semibold)
            .foregroundStyle(item.amount.isStatus ? PumColor.textSecondary : PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { texts; Spacer(minLength: 0); value.fixedSize() }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { texts; value } // 넘치면 아래로
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.spoken))
    }

    // MARK: 문서

    private var documentsCard: some View {
        PumCard {
            ForEach(Array(state.documents.enumerated()), id: \.element.id) { i, doc in
                if i > 0 { divider }
                Button { onOpenDocument(doc.kind) } label: { documentRow(doc) }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(doc.spoken))
            }
        }
    }

    private func documentRow(_ doc: AfterLeavingDocument) -> some View {
        let title = Text(doc.title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
        let value = Text(doc.valueText).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { title; Spacer(minLength: 0); value.fixedSize(); chevron }
            HStack(spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { title; value } // 넘치면 아래로
                Spacer(minLength: 0)
                chevron
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .contentShape(Rectangle())
    }

    // MARK: 경력증명서 요청

    private var certificateCard: some View {
        PumCard {
            Button(action: onRequestCertificate) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(AfterLeavingState.certificateTitle).pumText(.callout, weight: .semibold)
                            .foregroundStyle(PumColor.textPrimary)
                        Text(AfterLeavingState.certificateDetail).pumText(.caption)
                            .foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(state.certificateSpoken))
        }
    }
}

#Preview("10o 원문") { AfterLeavingView(state: .sample) }
#Preview("10o · 큰 글자") { AfterLeavingView(state: .sample).dynamicTypeSize(.accessibility3) }
