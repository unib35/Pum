import SwiftUI
import UIKit

/// 명세서 PDF(A4 한 장). 근로기준법 제48조 기재 항목: 이름 · 지급일 · 근무일수 · 근무시간 · 항목별 금액 · 공제 · 계산 방법(근거).
/// 화면 디자인이 아니라 인쇄 문서라 시스템 글꼴 · 검정 글자로 그린다.
struct PayslipDocument: View {
    let record: PayslipRecord
    let traceLines: [String]

    static let pageSize = CGSize(width: 595, height: 842)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("급여명세서").font(.system(size: 22, weight: .bold))
            Group {
                row("사업장", record.workplaceName)
                row("성명", record.employeeName)
                row("대상 기간", record.monthTitle)
                row("지급일", record.payDateText)
                row("근무", record.workSummary)
            }
            Divider()
            section("지급", record.earnings, total: ("지급 합계", record.grossTotal))
            section("공제", record.deductions, total: ("공제 합계", record.deductionTotal))
            Divider()
            HStack {
                Text("실지급액").font(.system(size: 15, weight: .bold))
                Spacer()
                Text(PumFormat.amount(record.netPay) + "원").font(.system(size: 17, weight: .bold))
            }
            if !traceLines.isEmpty {
                Divider()
                Text("계산 방법").font(.system(size: 12, weight: .semibold))
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(traceLines.enumerated()), id: \.offset) { Text($0.element) }
                }
                .font(.system(size: 9))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.black)
        .padding(40)
        .frame(width: Self.pageSize.width, height: Self.pageSize.height, alignment: .topLeading)
        .background(.white)
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(.gray)
            Spacer()
            Text(value)
        }
        .font(.system(size: 12))
    }

    private func section(_ title: String, _ lines: [PayslipLine], total: (String, Int)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold))
            if lines.isEmpty { row("없음", "0원") }
            ForEach(lines) { row($0.label, PumFormat.amount($0.amount) + "원") }
            HStack {
                Text(total.0).font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(PumFormat.amount(total.1) + "원").font(.system(size: 12, weight: .semibold))
            }
        }
    }

    /// 임시 폴더에 「2026년 9월 급여명세서 김민지.pdf」로 저장하고 주소를 돌려준다.
    @MainActor
    static func makeFile(_ record: PayslipRecord, traceLines: [String]) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(record.monthTitle) 급여명세서 \(record.employeeName).pdf")
        let renderer = ImageRenderer(content: PayslipDocument(record: record, traceLines: traceLines))
        var box = CGRect(origin: .zero, size: pageSize)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else { throw CocoaError(.fileWriteUnknown) }
        renderer.render { _, draw in
            pdf.beginPDFPage(nil)
            draw(pdf)
            pdf.endPDFPage()
        }
        pdf.closePDF()
        return url
    }
}

/// 시스템 공유 시트(파일 앱 저장 · 카카오톡 · 메일 · 인쇄)
struct SoloShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// 공유할 파일(시트 열기용)
struct SharedFile: Identifiable {
    let url: URL
    var id: URL { url }
}
