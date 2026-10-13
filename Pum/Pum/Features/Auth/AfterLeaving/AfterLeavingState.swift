// UI-IOS-10o · REQ-080 — 직원 · 퇴사 후 (읽기 전용)
// 날짜 · 기간(근속 포함) · 금액 · 상태 글자 · 문서 개수 · 보관 안내는 서버 값 그대로. 화면에서 계산하지 않는다.
import Foundation

/// 받을 돈의 값: 확정 금액(정수 원) 또는 서버가 준 상태 글자(「계산 중」)
nonisolated enum AfterLeavingAmount: Equatable, Sendable {
    case won(Int)
    case status(String)

    var text: String {
        switch self {
        case .won(let v): "\(PumFormat.amount(v))원"
        case .status(let s): s
        }
    }
    var isStatus: Bool {
        if case .status = self { return true }
        return false
    }
}

nonisolated struct AfterLeavingPayItem: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var amount: AfterLeavingAmount

    /// 상태 글자면 「퇴직금, 계산 중, 사업주 확정 후 알려드려요」, 금액이면 「10월 급여, 지급 대기 · …, 880,000원」
    var spoken: String {
        amount.isStatus ? "\(title), \(amount.text), \(detail)" : "\(title), \(detail), \(amount.text)"
    }
}

nonisolated enum AfterLeavingDocumentKind: String, Equatable, Sendable, CaseIterable {
    case contract, payslip, workRecord
}

nonisolated struct AfterLeavingDocument: Equatable, Sendable, Identifiable {
    var kind: AfterLeavingDocumentKind
    var title: String
    /// 「1건」 · 「15장」 · 「2025.8 – 2026.10」(서버 값)
    var valueText: String
    var id: String { kind.rawValue }

    var spoken: String { "\(title), \(valueText)" }
}

nonisolated struct AfterLeavingState: Equatable, Sendable {
    static let payTitle = "받을 돈"
    static let documentsTitle = "문서"
    static let certificateTitle = "경력증명서 요청"
    static let certificateDetail = "근무 기간 · 업무 · 사업주 확인"

    /// 사업장 이름(서버 값)
    var workplaceName: String
    /// 「2026년 10월 31일 퇴사」
    var leftTitle: String
    /// 「2025.8.18 – 2026.10.31 · 1년 2개월」
    var periodText: String
    /// 「소속 종료」
    var statusText: String
    var payItems: [AfterLeavingPayItem]
    var documents: [AfterLeavingDocument]
    /// 「계약서 · 명세서 · 근무기록은 퇴사 후 3년간 보관돼요.」
    var retentionNote: String

    var headerSpoken: String { "\(leftTitle), \(periodText), \(statusText)" }
    var certificateSpoken: String { "\(Self.certificateTitle), \(Self.certificateDetail)" }

    /// 원문 값
    static let sample = AfterLeavingState(
        workplaceName: "종민김밥 본점",
        leftTitle: "2026년 10월 31일 퇴사",
        periodText: "2025.8.18 \u{2013} 2026.10.31 \u{00B7} 1년 2개월",
        statusText: "소속 종료",
        payItems: [
            .init(id: "salary", title: "10월 급여", detail: "지급 대기 \u{00B7} 11월 14일까지", amount: .won(880_000)),
            .init(id: "severance", title: "퇴직금", detail: "사업주 확정 후 알려드려요", amount: .status("계산 중")),
            .init(id: "leave", title: "미사용 연차 수당", detail: "지급 대기", amount: .won(88_000)),
        ],
        documents: [
            .init(kind: .contract, title: "근로계약서", valueText: "1건"),
            .init(kind: .payslip, title: "급여명세서", valueText: "15장"),
            .init(kind: .workRecord, title: "근무기록", valueText: "2025.8 \u{2013} 2026.10"),
        ],
        retentionNote: "계약서 \u{00B7} 명세서 \u{00B7} 근무기록은 퇴사 후 3년간 보관돼요."
    )
}
