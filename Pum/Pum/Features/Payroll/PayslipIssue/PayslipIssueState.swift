// UI-IOS-10d · REQ-074 — 급여명세서 발행 데이터.
// 인원 · 금액 · 항목 점검 결과 · 부족 정보 · 버튼 인원수 · 안내 문구는 서버 값 그대로. 화면에서 세거나 더하지 않는다.
// 생년월일 같은 개인정보 값은 이 화면에 없다(「없음」 여부만) — 로그 금지.
import Foundation

/// 명세서를 직원에게 보내는 때 (선택지는 서버가 준다)
nonisolated struct PayslipSendTiming: Equatable, Sendable, Identifiable {
    var id: String       // 서버 코드 「on_paid」 · 「now」
    var title: String    // 「지급 완료 처리할 때」
}

nonisolated struct PayslipIssuePerson: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int
    var amount: Int               // 실지급액(정수 원, 서버 값)
    /// 부족한 정보 안내(서버 값, 예 「생년월일 없음」). nil이면 발행 가능.
    var missingText: String?
    /// 「요청 ›」을 보일지(서버 값)
    var canRequestInfo: Bool

    var amountText: String { PumFormat.amount(amount) }
    var amountSpokenText: String { PumFormat.amount(amount) + "원" }
    var accessibilityText: String {
        [name, amountSpokenText, missingText].compactMap { $0 }.joined(separator: ", ")
    }
}

/// 필수 기재 항목 한 칸 (점검 결과는 서버 값)
nonisolated struct PayslipRequiredItem: Equatable, Sendable, Identifiable {
    var id: String { title }
    var title: String            // 「성명 · 생년월일」
    var detail: String?          // 서버가 준 「3/4」. 없으면 nil
    var okCount: Int?            // 읽어 주기용 「3」
    var totalCount: Int?         // 「4」
    var isOk: Bool

    var displayText: String { detail.map { "\(title) \($0)" } ?? title }
    var accessibilityText: String {
        if let okCount, let totalCount { return "\(title), \(totalCount)명 중 \(okCount)명, \(isOk ? "확인됨" : "확인 필요")" }
        return "\(title), \(isOk ? "확인됨" : "확인 필요")"
    }
}

nonisolated struct PayslipIssueState: Equatable, Sendable {
    var title: String                  // 「10월 급여명세서」
    var periodText: String             // 「10월분 · 지급일 11월 10일」
    var waitingText: String            // 「발행 대기 4명」
    var statusBadgeText: String        // 「급여 확정됨」
    var timings: [PayslipSendTiming]
    var selectedTimingID: String
    var timingNote: String             // 「임금을 지급할 때 명세서를 함께 교부해야 해요」
    var peopleHeaderText: String       // 「직원 4명」
    var people: [PayslipIssuePerson]
    var requiredItems: [PayslipRequiredItem]
    var issueCount: Int                // 서버: 지금 발행할 수 있는 인원
    var blockedNote: String?           // 「박서준님은 생년월일을 받으면 발행돼요」

    static let timingHeader = "직원에게 보내는 때"
    static let requiredHeader = "필수 기재 항목"
    var issueButtonTitle: String { "\(issueCount)명 발행하기" }
    var canIssue: Bool { issueCount > 0 }
    var selectedTiming: PayslipSendTiming? { timings.first { $0.id == selectedTimingID } }

    static let sample = PayslipIssueState(
        title: "10월 급여명세서",
        periodText: "10월분 · 지급일 11월 10일",
        waitingText: "발행 대기 4명",
        statusBadgeText: "급여 확정됨",
        timings: [.init(id: "on_paid", title: "지급 완료 처리할 때"), .init(id: "now", title: "지금 바로")],
        selectedTimingID: "on_paid",
        timingNote: "임금을 지급할 때 명세서를 함께 교부해야 해요",
        peopleHeaderText: "직원 4명",
        people: [
            .init(id: "kim", name: "김하늘", colorIndex: 1, amount: 1_062_000, missingText: nil, canRequestInfo: false),
            .init(id: "lee", name: "이종민", colorIndex: 0, amount: 1_218_000, missingText: nil, canRequestInfo: false),
            .init(id: "choi", name: "최유나", colorIndex: 2, amount: 624_000, missingText: nil, canRequestInfo: false),
            .init(id: "park", name: "박서준", colorIndex: 3, amount: 880_000, missingText: "생년월일 없음", canRequestInfo: true),
        ],
        requiredItems: [
            .init(title: "성명 · 생년월일", detail: "3/4", okCount: 3, totalCount: 4, isOk: false),
            .init(title: "지급일", detail: nil, okCount: nil, totalCount: nil, isOk: true),
            .init(title: "임금 총액", detail: nil, okCount: nil, totalCount: nil, isOk: true),
            .init(title: "항목별 금액", detail: nil, okCount: nil, totalCount: nil, isOk: true),
            .init(title: "계산 방법", detail: nil, okCount: nil, totalCount: nil, isOk: true),
            .init(title: "공제 내역", detail: nil, okCount: nil, totalCount: nil, isOk: true),
        ],
        issueCount: 3,
        blockedNote: "박서준님은 생년월일을 받으면 발행돼요"
    )
}
