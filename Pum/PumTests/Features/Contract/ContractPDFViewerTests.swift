// UI-IOS-1ap · REQ-060 — PDF 뷰어 원문 값 · 쪽 읽기 문구 · 쪽 범위 보정
import Testing
import PDFKit
@testable import Pum

struct ContractPDFViewerTests {
    let s = ContractPDFViewerState.sample

    @Test func 원문_값() {
        #expect(s.fileName == "표준근로계약서.pdf")
        #expect(s.subtitle(pageIndex: 0, count: 3) == "1 / 3쪽 \u{00B7} 체결 2026.10.03")
        #expect(ContractPDFViewerState.unreadableText == "계약서를 열 수 없어요")
    }

    @Test func 읽기_문구() {
        #expect(s.headerSpoken(pageIndex: 0, count: 3) == "표준근로계약서.pdf, 1 / 3쪽 \u{00B7} 체결 2026.10.03")
        #expect(ContractPDFViewerState.dotsSpoken(pageIndex: 0, count: 3) == "3쪽 중 1쪽")
        #expect(ContractPDFViewerState.dotsSpoken(pageIndex: 2, count: 3) == "3쪽 중 3쪽")
    }

    @Test func 쪽_범위_보정() {
        #expect(ContractPDFViewerState.clampedPage(-1, count: 3) == 0)
        #expect(ContractPDFViewerState.clampedPage(5, count: 3) == 2)
        #expect(ContractPDFViewerState.clampedPage(1, count: 3) == 1)
        #expect(ContractPDFViewerState.clampedPage(4, count: 0) == 0)
    }

    @Test func 예시_PDF는_3쪽() {
        #expect(s.pdfData.flatMap { PDFDocument(data: $0) }?.pageCount == 3)
        #expect(PDFDocument(data: Data("x".utf8)) == nil)
    }
}
