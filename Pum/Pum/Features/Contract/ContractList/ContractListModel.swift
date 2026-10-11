// UI-IOS-1ab · REQ-060 — 계약서 보관함 데이터
// 계약 기간 · 시급 · 이력 문구는 서버가 준 값 그대로(화면에서 계산하지 않는다). 변경 단락은 서버가 준 이전 · 새 값으로 틀에 끼워 조합.
import SwiftUI

nonisolated enum ContractStatus: Equatable, Sendable {
    case signed          // 체결 완료 — 초록
    case changePending   // 변경 서명 대기 — 주황

    var badgeText: String {
        switch self {
        case .signed: "체결 완료"
        case .changePending: "변경 서명 대기"
        }
    }
}

/// 이력 한 줄: 「10/01 14:20」 + 「사업주 서명 · 박민수」
nonisolated struct ContractHistoryEntry: Equatable, Sendable, Identifiable {
    let order: Int
    let timeText: String
    let text: String
    var id: Int { order }
    /// 낭독용: 「10/01 14:20, 사업주 서명, 박민수」
    var accessibilityText: String { "\(timeText), " + text.replacingOccurrences(of: " · ", with: ", ") }
}

/// 조건 변경 계약서 알림: 이전 · 새 시급과 적용일은 서버 값
nonisolated struct ContractChangeNotice: Equatable, Sendable {
    let effectiveText: String   // 「11월 1일」
    let oldWageText: String     // 「11,500원」
    let newWageText: String     // 「12,000원」

    var leadText: String { "\(effectiveText)부터 시급 " }
    static let arrowText = " → "
    static let tailText = " 변경 계약서가 도착했어요."

    /// 화면 문구(서식 없이): 「11월 1일부터 시급 11,500원 → 12,000원 변경 계약서가 도착했어요.」
    var plainText: String { leadText + oldWageText + Self.arrowText + newWageText + Self.tailText }
    /// 낭독: 「11월 1일부터 시급 11,500원에서 12,000원으로 변경 계약서가 도착했어요」
    var accessibilityText: String { "\(leadText)\(oldWageText)에서 \(newWageText)으로 변경 계약서가 도착했어요" }
}

nonisolated struct ContractItem: Equatable, Sendable, Identifiable {
    let id: Int
    let workplaceName: String
    /// 사업장 색 네모 글자(「종」)
    let initial: String
    /// `PumAvatarPalette.stores` 순서 번호
    let colorIndex: Int
    let startText: String       // 「2026.10.05」
    let endText: String         // 「2027.04.04」
    let wageText: String        // 「12,000원」
    let status: ContractStatus
    var isExpanded: Bool
    var history: [ContractHistoryEntry] = []
    var change: ContractChangeNotice? = nil

    /// 「2026.10.05 – 2027.04.04 · 시급 12,000원」 (en dash)
    var summaryText: String { "\(startText) \u{2013} \(endText) · 시급 \(wageText)" }

    var hasHistory: Bool { !history.isEmpty }
    /// 펼쳤을 때 이력 · 버튼 영역(체결 완료 + 이력 있음)
    var showsDetail: Bool { isExpanded && status == .signed && hasHistory }
    /// 변경 단락은 변경 서명 대기에서만
    var showsChange: Bool { status == .changePending && change != nil }
    var isAttention: Bool { status == .changePending }
    /// 카드 머리가 눌림으로 펼침을 바꾸는지 — 펼칠 내용이 있을 때만
    var isExpandable: Bool { status == .signed && hasHistory }

    /// 「종민김밥 본점, 체결 완료, 2026.10.05부터 2027.04.04까지, 시급 12,000원, 펼쳐짐」
    var headerAccessibilityText: String {
        var s = "\(workplaceName), \(status.badgeText), \(startText)부터 \(endText)까지, 시급 \(wageText)"
        if isExpandable { s += isExpanded ? ", 펼쳐짐" : ", 접힘" }
        return s
    }
}

nonisolated struct ContractListRecord: Equatable, Sendable {
    var items: [ContractItem]

    mutating func toggle(id: Int) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].isExpandable else { return }
        items[i].isExpanded.toggle()
    }

    static let sample = ContractListRecord(items: [
        ContractItem(id: 1, workplaceName: "종민김밥 본점", initial: "종", colorIndex: 0,
                     startText: "2026.10.05", endText: "2027.04.04", wageText: "12,000원",
                     status: .signed, isExpanded: true,
                     history: [
                        .init(order: 1, timeText: "10/01 14:20", text: "사업주 서명 · 박민수"),
                        .init(order: 2, timeText: "10/03 16:41", text: "근로자 서명 · 이종민 (휴대폰 본인인증)"),
                        .init(order: 3, timeText: "10/03 16:41", text: "PDF 생성 · 양측 교부"),
                     ]),
        ContractItem(id: 2, workplaceName: "B카페 서면점", initial: "B", colorIndex: 1,
                     startText: "2026.03.01", endText: "2027.02.28", wageText: "11,500원",
                     status: .changePending, isExpanded: false,
                     change: .init(effectiveText: "11월 1일", oldWageText: "11,500원", newWageText: "12,000원")),
        ContractItem(id: 3, workplaceName: "C학원", initial: "C", colorIndex: 2,
                     startText: "2026.09.01", endText: "2027.02.28", wageText: "15,000원",
                     status: .signed, isExpanded: false),
    ])
}
