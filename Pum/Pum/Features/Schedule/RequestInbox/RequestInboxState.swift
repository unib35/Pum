// UI-IOS-10k · REQ-042 — 사장님 휴무·변경 요청 처리: 서버(엔진)가 준 값을 그대로 담는다.
// 인원 · 금액 · 상대 시각 · 버튼 문구는 화면에서 계산하지 않는다(여기서는 서버 문자열만 보여 준다).
import Foundation

nonisolated enum RequestKind: Equatable, Sendable { case leave, shiftChange }
nonisolated enum RequestDecision: Equatable, Sendable { case approve, reject }

/// 영향 상자의 한 행. 서버가 준 라벨 · 값 · (선택) 부족 알약.
nonisolated struct RequestImpactRow: Equatable, Sendable, Identifiable {
    var id: String { label }
    let label: String
    let value: String
    /// 서버가 부족 표시를 줄 때만 (예: 「필요 3명」)
    var shortageText: String?
}

nonisolated struct RequestItem: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let colorIndex: Int
    let kind: RequestKind
    let kindText: String        // 「휴무」 · 「근무 변경」
    let relativeTime: String    // 「10분 전」
    let titleText: String       // 「10월 23일 금 · 17:00 – 22:00」
    let detailText: String
    let impacts: [RequestImpactRow]
    let rejectText: String
    let approveText: String     // 서버 값

    var accessibilityHeader: String { "\(name), \(kindText) 요청, \(relativeTime)" }
    var rejectAccessibility: String { "\(name) 요청 \(rejectText)" }
    var approveAccessibility: String { "\(name) 요청 \(approveText)" }
    var accessibilityImpacts: String {
        impacts.map { r in ([r.label, r.value] + (r.shortageText.map { [$0] } ?? [])).joined(separator: ", ") }.joined(separator: ". ")
    }
}

nonisolated struct RequestInboxState: Equatable, Sendable {
    var title: String
    var items: [RequestItem]

    static let sample = RequestInboxState(
        title: "요청 2건",
        items: [
            RequestItem(
                id: "req-leave", name: "김하늘", colorIndex: 1, kind: .leave, kindText: "휴무", relativeTime: "10분 전",
                titleText: "10월 23일 금 · 17:00 – 22:00", detailText: "무급 휴무 · 병원 예약이 있어요",
                impacts: [
                    RequestImpactRow(label: "금 17–22 근무자", value: "3명 → 2명", shortageText: "필요 3명"),
                    RequestImpactRow(label: "대타 지원", value: "박서준 · 수락함"),
                ],
                rejectText: "거절", approveText: "박서준 대타로 승인"),
            RequestItem(
                id: "req-change", name: "박서준", colorIndex: 3, kind: .shiftChange, kindText: "근무 변경", relativeTime: "1시간 전",
                titleText: "10월 21일 수 · 18:00 – 23:00", detailText: "기존 17:00 – 22:00 · 수업이 18시에 끝나요",
                impacts: [
                    RequestImpactRow(label: "필요 인력", value: "그대로 충족"),
                    RequestImpactRow(label: "인건비 · 예상", value: "+5,500원 · 야간 가산 1시간"),
                ],
                rejectText: "거절", approveText: "승인"),
        ])
}

/// 누른 카드만 잠근다. 실패하면 풀고, 서버 새 상태가 오면 모두 푼다(8b WorkClosingRowLock과 같은 규칙).
nonisolated struct RequestRowLock: Equatable, Sendable {
    /// 처리 중인 카드 → 누른 결정(처리 중 표시를 누른 버튼에만)
    private(set) var processing: [String: RequestDecision] = [:]
    func isLocked(_ id: String) -> Bool { processing[id] != nil }
    func decision(_ id: String) -> RequestDecision? { processing[id] }
    /// 처음 누르면 true를 돌려주고 잠근다. 이미 처리 중이면 false.
    mutating func begin(_ id: String, _ decision: RequestDecision) -> Bool {
        guard processing[id] == nil else { return false }
        processing[id] = decision
        return true
    }
    mutating func finish(_ id: String, success: Bool) { if !success { processing[id] = nil } }
    /// 서버 새 목록 — 사라졌거나 내용이 바뀐 카드의 잠금만 푼다(진행 중인 다른 카드는 그대로)
    mutating func refresh(old: [RequestItem], new: [RequestItem]) {
        for id in processing.keys {
            let before = old.first { $0.id == id }, after = new.first { $0.id == id }
            if after == nil || after != before { processing[id] = nil }
        }
    }
}
