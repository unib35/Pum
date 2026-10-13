// UI-IOS-2h · REQ-005 — 초대 수락 → 전환 화면 데이터
// 이름 · 기간 · 일수 · 날짜 · 조건은 서버 값 그대로(화면에서 만들거나 계산하지 않는다).
import Foundation

nonisolated struct InviteSwitchState: Equatable, Sendable {
    var ownerName: String          // 「박민수」 — 사장님 호칭은 화면이 붙임
    var workplaceName: String
    // 지금: 개인 기록
    var personalName: String       // 「종민김밥」
    var personalPeriod: String     // 「4~10월 · 86일 기록」 — 서버가 준 기간 · 일수 문구
    // 수락 후: 사업장 기록
    var startDate: String          // 「10월 5일부터」
    var payrollMonth: String       // 안내 문장 속 달 — 「10월」
    // 제안 근로조건
    var hourlyWage: String         // 「12,000원」
    /// 비교 결과 플래그(서버) — 다르면 문구를 숨긴다(다를 때 문구는 디자인에 없음)
    var wageMatchesMine: Bool
    var schedule: String           // 「월·수·금 17:00 – 22:00」
    var payday: String             // 「매월 10일」

    var titleLead: String { "\(ownerName) 사장님이" }
    var titleTail: String { "에 초대했어요" }
    var titleText: String { "\(titleLead) \(workplaceName)\(titleTail)" }

    static let personalDetail = "내가 입력 · 자유 수정"
    static let workplaceDetail = "출퇴근 기록 · 수정 요청"
    static let badgeText = "사업장 확인"
    static let matchText = "내 설정과 같음"

    /// VoiceOver — 지금 → 수락 후 순서대로
    var comparisonAccessibilityText: String {
        "지금: 내 기록, \(personalName), \(personalPeriod), \(Self.personalDetail). 수락 후: \(Self.badgeText), \(workplaceName), \(startDate), \(Self.workplaceDetail)"
    }
    var noteBold: String { "그대로 남고" }
    var noteText: String {
        "지난 개인 기록은 \(noteBold) 사업장 기록으로 옮겨지지 않아요. \(payrollMonth) 급여는 사장님이 사업장 기록으로 계산해요."
    }

    var wageAccessibilityText: String {
        wageMatchesMine ? "시급, \(hourlyWage), \(Self.matchText)" : "시급, \(hourlyWage)"
    }

    static let sample = InviteSwitchState(
        ownerName: "박민수", workplaceName: "종민김밥 본점",
        personalName: "종민김밥", personalPeriod: "4~10월 · 86일 기록",
        startDate: "10월 5일부터", payrollMonth: "10월",
        hourlyWage: "12,000원", wageMatchesMine: true,
        schedule: "월·수·금 17:00 – 22:00", payday: "매월 10일")
}

/// 「초대 수락」 한 번만 — 처리 중 잠금, 실패하면 풀림
nonisolated struct InviteSwitchLock: Equatable, Sendable {
    private(set) var isSending = false
    /// 보낼 수 있으면 true를 돌려주고 잠근다. 이미 처리 중이면 false.
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    /// 실패하면 풀어 다시 누를 수 있게, 성공이면 잠근 채 둔다
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
