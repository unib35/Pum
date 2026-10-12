// UI-IOS-10i · REQ-042 — 직원 휴무 신청: 쉬려는 근무 · 쉬는 방식 · 대타 같이 · 사유. 승인 전까지는 예정대로 근무.
// 연차 잔여 · 발생 예정 문구 · 동료 수는 서버 값 그대로 — 화면에서 계산 · 판단하지 않는다(연차 선택 가능 여부도 서버 isSelectable).
import Foundation

nonisolated enum LeaveMethod: Equatable, Sendable { case unpaid, annual }

nonisolated struct LeaveMethodOption: Equatable, Identifiable, Sendable {
    var method: LeaveMethod
    var title: String
    /// 서버 문구 — 예: 「지금 0시간 · 11월 6일에 3.6시간 생겨요」
    var detail: String
    /// 서버가 정한다. 화면에서 연차 잔여로 판단하지 않는다.
    var isSelectable: Bool
    var id: LeaveMethod { method }
}

/// 보내는 값 — 근무 id · 방식 · 대타 같이 · 사유(비면 nil)
nonisolated struct LeaveRequest: Equatable, Sendable {
    var shiftId: String
    var method: LeaveMethod
    var withSubstitute: Bool
    var reason: String?
}

nonisolated struct LeaveRequestState: Equatable, Sendable {
    var shiftId: String
    /// 예: 「10월 23일 금 · 17:00 – 22:00」 (Asia/Seoul, 서버 문구)
    var shiftTitle: String
    /// 예: 「종민김밥 본점 · 예정 근무」
    var shiftSubtitle: String
    var methods: [LeaveMethodOption]
    /// 같은 사업장 동료 수 — 서버 값
    var colleagueCount: Int

    static let headerTitle = "휴무 신청"
    static let shiftLabel = "쉬려는 근무"
    static let changeTitle = "변경"
    static let methodHeader = "쉬는 방식"
    static let substituteTitle = "대타 요청도 같이 보내기"
    static let reasonHeader = "사유 · 선택"
    static let sendTitle = "휴무 요청 보내기"
    /// 원문 없음 — 21c의 「보내는 중」과 같게
    static let sendingTitle = "보내는 중"
    static let notice = "사장님이 승인하기 전까지는 예정대로 근무예요"
    /// 원문 없음 — 1i와 같은 값
    static let reasonLimit = 200

    var colleaguesText: String { "같은 사업장 동료 \(colleagueCount)명에게" }

    var shiftAccessibility: String { "\(Self.shiftLabel), \(shiftTitle), \(shiftSubtitle)" }

    static func clampedReason(_ s: String) -> String {
        s.count > reasonLimit ? String(s.prefix(reasonLimit)) : s
    }

    /// VoiceOver 한 줄 — 「무급 휴무, 이날 근무시간은 급여에서 빠져요, 선택됨」
    static func optionAccessibility(_ option: LeaveMethodOption, isOn: Bool) -> String {
        "\(option.title), \(option.detail), \(isOn ? "선택됨" : "선택 안 됨")"
    }

    static func substituteAccessibility(isOn: Bool) -> String { "\(substituteTitle), \(isOn ? "켬" : "끔")" }

    /// 원문 캡처 값
    static let sample = LeaveRequestState(
        shiftId: "shift-1023", shiftTitle: "10월 23일 금 · 17:00 – 22:00", shiftSubtitle: "종민김밥 본점 · 예정 근무",
        methods: [
            LeaveMethodOption(method: .unpaid, title: "무급 휴무", detail: "이날 근무시간은 급여에서 빠져요", isSelectable: true),
            LeaveMethodOption(method: .annual, title: "연차 사용", detail: "지금 0시간 · 11월 6일에 3.6시간 생겨요", isSelectable: true),
        ],
        colleagueCount: 4)
}

/// 사용자가 고친 값. 무급 휴무 선택 · 대타 켬이 원문 시작값.
nonisolated struct LeaveRequestDraft: Equatable, Sendable {
    var method: LeaveMethod = .unpaid
    var withSubstitute = true
    var reason = ""

    /// 서버가 고를 수 없다고 한 방식은 바꾸지 않는다
    mutating func select(_ option: LeaveMethodOption) {
        guard option.isSelectable else { return }
        method = option.method
    }

    func request(for state: LeaveRequestState) -> LeaveRequest {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return LeaveRequest(shiftId: state.shiftId, method: method, withSubstitute: withSubstitute,
                            reason: trimmed.isEmpty ? nil : LeaveRequestState.clampedReason(trimmed))
    }
}

/// 보내기는 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
nonisolated struct LeaveRequestLock: Equatable, Sendable {
    private(set) var isSending = false
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
