// UI-IOS-20h · 1m — 명세서 PDF · 보내기 화면 값
import Foundation
import PDFKit
import SwiftData
import Testing
@testable import Pum

@MainActor
struct PayslipDocumentTests {
    @Test func 확정_명세서를_PDF_한_장으로() throws {
        let store = try DataTestStore()
        let (workplace, employee) = try store.makeEmployee()
        try SoloPayroll.useCase(store.context).close(workplace, year: 2026, month: 9)

        let file = try #require(SoloPayroll.pdfFile(workplace, employeeID: "\(employee.persistentModelID)",
                                                    year: 2026, month: 9, context: store.context))
        #expect(file.url.lastPathComponent == "2026년 9월 급여명세서 김민지.pdf")
        let pdf = try #require(PDFDocument(url: file.url))
        #expect(pdf.pageCount == 1)
        let text = pdf.string ?? ""
        #expect(text.contains("급여명세서"))
        #expect(text.contains("실지급액"))
        try? FileManager.default.removeItem(at: file.url)
    }

    @Test func 보내기_화면은_PDF만() throws {
        let store = try DataTestStore()
        let (workplace, _) = try store.makeEmployee()
        try SoloPayroll.useCase(store.context).close(workplace, year: 2026, month: 9)

        let state = SoloPayroll.sendState(workplace, year: 2026, month: 9, context: store.context)
        #expect(state.isSolo)
        #expect(state.monthText == "2026년 9월분 · 지급일 10월 10일")
        #expect(state.pdfRecipients.count == 1)
        #expect(state.recipients.first?.methodText == "PDF")
        #expect(SoloPayroll.record(workplace, year: 2026, month: 9, context: store.context).showsSendButton)
    }
}
