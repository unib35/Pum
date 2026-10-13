// UI-IOS-1ap — 프리뷰 · 개발 메뉴용 예시 PDF(3쪽). 앱 본 코드에는 들어가지 않는다.
#if DEBUG
import UIKit

extension ContractPDFViewerState {
    static let sample = ContractPDFViewerState(
        fileName: "표준근로계약서.pdf", signedText: "체결 2026.10.03", pdfData: ContractPDFFixture.makePDF())
}

enum ContractPDFFixture {
    static func makePDF() -> Data {
        let size = CGSize(width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
        return renderer.pdfData { ctx in
            let title: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22, weight: .bold)]
            let body: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            let lines = [
                "1. 근로계약기간 : 2026년 10월 5일부터 2027년 4월 4일까지",
                "2. 근무장소 : 종민김밥 본점 (부산 김해시 장유로 12)",
                "3. 업무의 내용 : 홀 서빙 및 마감 정리",
                "4. 근로일 및 근로시간 : 매주 월·수·금 17:00 ~ 22:00",
                "5. 휴게시간 : 19:30 ~ 20:00 (30분)",
                "6. 임금 : 시간급 12,000원",
            ]
            for page in 0..<3 {
                ctx.beginPage()
                if page == 0 {
                    "표준근로계약서".draw(at: CGPoint(x: 200, y: 60), withAttributes: title)
                    for (i, line) in lines.enumerated() {
                        line.draw(at: CGPoint(x: 50, y: 130 + CGFloat(i) * 32), withAttributes: body)
                    }
                    "연락처 : 010-****-4821".draw(at: CGPoint(x: 50, y: 400), withAttributes: body)
                } else {
                    "\(page + 1)쪽".draw(at: CGPoint(x: 50, y: 60), withAttributes: body)
                }
            }
        }
    }
}
#endif
