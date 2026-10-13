// UI-IOS-1ap · REQ-060 — 근로계약서 전문 PDF 뷰어 상태. 계약서 본문은 서버가 만든 PDF — 앱은 그리지 않는다.
import Foundation

nonisolated struct ContractPDFViewerState: Equatable, Sendable {
    /// 서버 값 — 예: 「표준근로계약서.pdf」
    var fileName: String
    /// 서버 값 — 예: 「체결 2026.10.03」
    var signedText: String
    /// 서버 PDF. 못 읽으면 nil이거나 PDF가 아닌 값
    var pdfData: Data?

    /// 본문 자리 안내(원문 없음 — 임시 문구)
    static let unreadableText = "계약서를 열 수 없어요"

    /// 쪽 번호(0부터)를 0...(count-1)로 보정. 쪽이 없으면 0
    static func clampedPage(_ page: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(page, 0), count - 1)
    }

    /// 「1 / 3쪽 · 체결 2026.10.03」 — pageIndex는 0부터
    func subtitle(pageIndex: Int, count: Int) -> String {
        let page = Self.clampedPage(pageIndex, count: count) + 1
        return "\(page) / \(count)쪽 \u{00B7} \(signedText)"
    }

    /// 머리 읽기 문구
    func headerSpoken(pageIndex: Int, count: Int) -> String {
        "\(fileName), \(subtitle(pageIndex: pageIndex, count: count))"
    }

    /// 쪽 점 읽기 문구 — 「3쪽 중 1쪽」
    static func dotsSpoken(pageIndex: Int, count: Int) -> String {
        "\(count)쪽 중 \(clampedPage(pageIndex, count: count) + 1)쪽"
    }
}
