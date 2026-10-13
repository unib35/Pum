// UI-IOS-1ap · REQ-060 — 근로계약서 전문(PDF 뷰어). 머리 · 쪽 점 · 버튼만 앱이 그리고 본문은 서버 PDF.
import SwiftUI
import PDFKit

struct ContractPDFViewerView: View {
    var state: ContractPDFViewerState
    var onBack: () -> Void = {}
    var onShare: () -> Void = {}
    var onSavePDF: () -> Void = {}

    @State private var document: PDFDocument?
    @State private var pageIndex = 0
    @ScaledMetric(relativeTo: .body) private var circleSize = PumTokens.Size.tapMin - PumTokens.Space.s4 // 원문 40
    @ScaledMetric(relativeTo: .body) private var dotSize = PumTokens.Space.s8

    init(state: ContractPDFViewerState, onBack: @escaping () -> Void = {}, onShare: @escaping () -> Void = {}, onSavePDF: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onShare = onShare
        self.onSavePDF = onSavePDF
        _document = State(initialValue: state.pdfData.flatMap { PDFDocument(data: $0) })
    }

    private var pageCount: Int { document?.pageCount ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            bottomBar
        }
        .background(PumTokens.ColorToken.gray200) // 원문 #E3E6EC
    }

    // MARK: 머리

    private var header: some View {
        HStack(spacing: PumTokens.Space.s8) {
            circleButton("chevron.left", label: "뒤로", action: onBack)
            VStack(spacing: PumTokens.Space.s2) {
                Text(state.fileName).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                if pageCount > 0 {
                    Text(state.subtitle(pageIndex: pageIndex, count: pageCount))
                        .pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(pageCount > 0 ? state.headerSpoken(pageIndex: pageIndex, count: pageCount) : state.fileName))
            .accessibilityAddTraits(.isHeader)
            circleButton("square.and.arrow.up", label: "공유", action: onShare)
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s10)
        .background(PumColor.bgApp)
        .overlay(alignment: .bottom) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
    }

    /// 보이는 모양은 원문 원(40), 누름 영역만 44 이상
    private func circleButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: PumLayout.navIcon, weight: .medium))
                .foregroundStyle(PumColor.textPrimary)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.surfaceCard, in: Circle())
                .overlay(Circle().stroke(PumColor.borderHairline, lineWidth: 1))
                .padding(PumTokens.Space.s2)
                .contentShape(Rectangle())
                .padding(-PumTokens.Space.s2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    // MARK: 본문

    @ViewBuilder private var content: some View {
        if let document {
            PDFKitView(document: document) { index in
                pageIndex = ContractPDFViewerState.clampedPage(index, count: document.pageCount)
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.top, PumTokens.Space.s14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text(ContractPDFViewerState.unreadableText)
                .pumText(.body, weight: .medium).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(PumTokens.Size.screenPad)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: 아래 줄

    private var bottomBar: some View {
        HStack(spacing: PumTokens.Space.s8) {
            if pageCount > 0 { dots }
            Spacer(minLength: PumTokens.Space.s8)
            pillButton("공유", filled: false, action: onShare)
            pillButton("PDF 저장", filled: true, action: onSavePDF)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s10)
        .padding(.bottom, PumTokens.Space.s10) // 원문 아래 40은 홈 표시 막대 자리 — 안전 영역이 대신한다
        .background(PumColor.bgApp)
        .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
    }

    private var dots: some View {
        HStack(spacing: PumTokens.Space.s6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(i == pageIndex ? PumTokens.ColorToken.gray900 : PumTokens.ColorToken.gray300)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(ContractPDFViewerState.dotsSpoken(pageIndex: pageIndex, count: pageCount)))
    }

    /// 보이는 모양은 원문 알약(padding 9 14), 누름 영역만 44 이상
    private func pillButton(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).pumText(.footnote, weight: .semibold)
                .foregroundStyle(filled ? Color.white : PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Space.s14)
                .padding(.vertical, PumTokens.Space.s10) // 원문 9 → 10
                .background(filled ? PumColor.surfaceInverse : PumColor.surfaceCard, in: Capsule())
                .overlay(Capsule().stroke(PumColor.borderHairline, lineWidth: filled ? 0 : 1))
                .padding(.vertical, PumTokens.Space.s12)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s12)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("1ap") { ContractPDFViewerView(state: .sample) }
#Preview("1ap · 큰 글자") { ContractPDFViewerView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("1ap · 못 읽음") {
    ContractPDFViewerView(state: ContractPDFViewerState(fileName: "표준근로계약서.pdf", signedText: "체결 2026.10.03", pdfData: nil))
}
#endif
