// UI-IOS-20g · REQ-007 — 근무 마감: 앱 없는 직원은 한 달 기록을 사장님이 한 번 확인해야 마감 가능
// 모든 값은 서버가 준 그대로. 남은 건수 · 마감 가능 여부를 화면에서 계산하지 않는다.
import Foundation

nonisolated struct WorkClosingDirectState: Equatable, Sendable {
    /// 사장님이 고친 날 한 줄
    nonisolated struct EditedDay: Equatable, Sendable, Identifiable {
        let id: String
        let dateText: String    // 예 「9월 25일 금」
        let detailText: String  // 예 「결근 · 사유 없음」
        /// 읽기: 「9월 25일 금, 결근 · 사유 없음, 고침」
        var spokenText: String { "\(dateText), \(detailText), 고침" }
    }

    /// 앱 없는 직원 한 명 — 확인 행과 고친 날 카드의 단위
    nonisolated struct Person: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        let scheduledDayCount: Int
        let scheduledPattern: String   // 예 「월 · 수 · 금 17–22」
        let editedDayCount: Int
        let editedDays: [EditedDay]
        /// MVP: 모두 앱 없는 직원이라 「앱 없음」을 빼고 쓴다
        var isSolo = false

        func confirmTitle(month: Int) -> String { "\(name) \u{00B7} \(month)월 기록 확인" }
        var confirmSubtitle: String {
            let counts = "예정대로 \(scheduledDayCount)일 \u{00B7} 고친 날 \(editedDayCount)일"
            return isSolo ? counts : "앱 없음 \u{00B7} \(counts)"
        }
        var editedTitle: String { "\(name) \u{00B7} 고친 날 \(editedDayCount)일" }
        var scheduledTitle: String { "예정대로 \(scheduledDayCount)일" }
    }

    let month: Int
    let periodText: String          // 서버가 준 기간, 예 「9월 1일 – 30일」
    let appStaffCount: Int          // 앱 출퇴근 기록 직원 수
    let appPendingCount: Int        // 앱 출퇴근 기록에서 확인할 것
    let people: [Person]            // 확인할 앱 없는 직원(0명이면 빈 목록)
    let remainingCount: Int         // 서버가 준 남은 건수
    let canClose: Bool              // 서버가 준 마감 가능 여부
    /// MVP(DEC-033): 「앱 출퇴근 기록」 줄을 숨긴다
    var isSolo = false
    /// MVP(DEC-033): 확인할 것이 없는 직원 — 「앱 출퇴근 기록」과 같은 ✓ 줄로 보인다
    var checked: [CheckedPerson] = []

    nonisolated struct CheckedPerson: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        let subtitle: String    // 예 「예정대로 22일」
    }

    var title: String { "\(month)월 근무 마감" }
    var appRecordSubtitle: String { "직원 \(appStaffCount)명 \u{00B7} 확인할 것 \(appPendingCount)건" }
    /// 활성 문구는 원문에 없음 — 「9월 근무 마감」까지만(8a와 같은 방식)
    var closeTitle: String { canClose ? title : "근무 마감 \u{00B7} \(remainingCount)건 남음" } // 원문 비활성 문구엔 달이 없다
    var closeAccessibilityLabel: String { canClose ? title : "\(title), \(remainingCount)건 남아 마감할 수 없음" }
    /// 마감이 잠겨 있을 때 이유 — 화면에는 보이지 않는 읽기 문구
    var closeHint: String? { canClose ? nil : "확인할 것이 \(remainingCount)건 남았어요" }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = WorkClosingDirectState(
        month: 9, periodText: "9월 1일 \u{2013} 30일", appStaffCount: 3, appPendingCount: 0,
        people: [Person(
            id: "minji", name: "김민지", scheduledDayCount: 11, scheduledPattern: "월 \u{00B7} 수 \u{00B7} 금 17\u{2013}22",
            editedDayCount: 2,
            editedDays: [
                EditedDay(id: "d25", dateText: "9월 25일 금", detailText: "결근 \u{00B7} 사유 없음"),
                EditedDay(id: "d16", dateText: "9월 16일 수", detailText: "15:50 \u{2013} 22:00 \u{00B7} +1시간 10분"),
            ])],
        remainingCount: 1, canClose: false)

    /// 확인할 직원이 없을 때 — 마감 버튼 활성
    static let allConfirmed = WorkClosingDirectState(
        month: 9, periodText: "9월 1일 \u{2013} 30일", appStaffCount: 3, appPendingCount: 0,
        people: [], remainingCount: 0, canClose: true)
}

/// 처리 중 잠금 — 확인은 한 번에 한 명, 마감은 한 번만. 성공이면 마감은 잠근 채(실패일 때만 풀림).
nonisolated struct WorkClosingDirectLock: Equatable, Sendable {
    private(set) var confirmingID: String?
    private(set) var isClosing = false

    /// 확인을 시작할 수 있으면 true를 돌려주고 그 직원만 처리 중으로 둔다
    mutating func beginConfirm(id: String) -> Bool {
        guard confirmingID == nil, !isClosing else { return false }
        confirmingID = id
        return true
    }
    /// 성공이면 서버 새 값이 오고 실패여도 그대로 — 어느 쪽이든 풀린다
    mutating func finishConfirm() { confirmingID = nil }

    mutating func beginClose(canClose: Bool) -> Bool {
        guard canClose, !isClosing, confirmingID == nil else { return false }
        isClosing = true
        return true
    }
    mutating func finishClose(success: Bool) { if !success { isClosing = false } }
}
