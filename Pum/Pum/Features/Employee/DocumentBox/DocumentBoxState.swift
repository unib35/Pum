// UI-IOS-6k · REQ-061 — 내 문서함(직원). 문서 목록 · 연도 묶음 · 상태 글자는 서버가 준 값. 화면은 계산하지 않는다.
import Foundation

/// 종류 칩 — 서버가 준 문서 종류 값으로 거른다
nonisolated enum DocumentFilter: String, CaseIterable, Sendable {
    case all, contract, payslip, certificate, submitted

    var title: String {
        switch self {
        case .all: "전체"
        case .contract: "계약서"
        case .payslip: "명세서"
        case .certificate: "확인서"
        case .submitted: "제출 서류"
        }
    }
}

/// 서버가 준 문서 종류
nonisolated enum DocumentKind: String, Sendable {
    case contract, payslip, certificate, submitted
}

/// 문서 상태 — 배지 종류와 행 동작이 여기서 정해진다
nonisolated enum DocumentStatus: Sendable {
    case signRequest   // 서명 요청(확인 필요)
    case signed        // 체결 완료
    case paid          // 지급 완료
    case issuable      // 바로 발급 가능 — 배지 대신 「발급」 버튼
    case expiring      // 만료 임박(N일 남음)
    case submitted     // 제출 완료

    var badgeKind: PumBadge.Kind? {
        switch self {
        case .signRequest, .expiring: .attention
        case .signed, .paid: .done
        case .issuable: nil
        case .submitted: .waiting
        }
    }
}

nonisolated struct DocumentItem: Identifiable, Equatable, Sendable {
    let id: String
    let kind: DocumentKind
    let title: String
    let detail: String
    let status: DocumentStatus
    /// 서버 글자(예: 「지급 완료」 · 「42일 남음」 · 「발급」)
    let statusText: String

    /// VoiceOver — 「급여명세서 9월, 종민김밥 본점 · 1,152,000원, 지급 완료」
    var accessibilityText: String { "\(title), \(detail), \(statusText)" }
}

nonisolated struct DocumentYearGroup: Identifiable, Equatable, Sendable {
    let year: String
    let items: [DocumentItem]
    var id: String { year }
}

nonisolated struct DocumentBoxState: Equatable, Sendable {
    static let headerTitle = "내 문서"
    static let workplaceFilterTitle = "전체 사업장"
    static let attentionHeader = "확인이 필요한 문서"
    static let footnote = "사장님은 직원별 문서함을 보고, 나는 내 문서만 봐요."

    let attention: [DocumentItem]
    let years: [DocumentYearGroup]

    func attention(under filter: DocumentFilter) -> [DocumentItem] { attention.filter { Self.matches($0, filter) } }

    /// 거른 뒤 빈 연도는 뺀다
    func years(under filter: DocumentFilter) -> [DocumentYearGroup] {
        years.compactMap { group in
            let items = group.items.filter { Self.matches($0, filter) }
            return items.isEmpty ? nil : DocumentYearGroup(year: group.year, items: items)
        }
    }

    private static func matches(_ item: DocumentItem, _ filter: DocumentFilter) -> Bool {
        switch filter {
        case .all: true
        case .contract: item.kind == .contract
        case .payslip: item.kind == .payslip
        case .certificate: item.kind == .certificate
        case .submitted: item.kind == .submitted
        }
    }

    static let sample = DocumentBoxState(
        attention: [
            DocumentItem(id: "change-contract", kind: .contract, title: "변경 근로계약서",
                         detail: "B카페 서면점 · 11/1부터 시급 12,000원", status: .signRequest, statusText: "서명 요청"),
        ],
        years: [
            DocumentYearGroup(year: "2026", items: [
                DocumentItem(id: "contract-2026", kind: .contract, title: "근로계약서",
                             detail: "종민김밥 본점 · 2026.10.03 체결", status: .signed, statusText: "체결 완료"),
                DocumentItem(id: "payslip-main", kind: .payslip, title: "급여명세서 9월",
                             detail: "종민김밥 본점 · 1,152,000원", status: .paid, statusText: "지급 완료"),
                DocumentItem(id: "payslip-c", kind: .payslip, title: "급여명세서 9월",
                             detail: "C학원 · 365,000원", status: .paid, statusText: "지급 완료"),
                DocumentItem(id: "work-cert", kind: .certificate, title: "근무확인서",
                             detail: "종민김밥 본점 · 바로 발급 가능", status: .issuable, statusText: "발급"),
                DocumentItem(id: "health-cert", kind: .submitted, title: "건강진단결과서",
                             detail: "제출함 · 2026.11.14 만료", status: .expiring, statusText: "42일 남음"),
                DocumentItem(id: "bankbook", kind: .submitted, title: "통장 사본",
                             detail: "제출함 · 종민김밥 본점 · B카페", status: .submitted, statusText: "제출 완료"),
            ]),
        ])
}
