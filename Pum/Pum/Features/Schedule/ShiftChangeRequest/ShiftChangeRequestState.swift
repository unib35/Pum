// UI-IOS-10j · REQ-042 — 직원 근무 변경 요청: 지금 근무 · 바꿀 시간(출근/퇴근 −/+) · 반영되면 · 사유. 승인 전까지는 예정대로(REQ-042).
// 「반영되면」 문구(근무시간 · 22시 이후 가산 안내)는 서버(급여 엔진) 값 그대로 — 화면에서 계산 · 판단하지 않는다.
// 시간은 Asia/Seoul 기준, 하루 안의 분(0–1440)으로만 다룬다.
import Foundation

/// 엔진이 돌려준 미리보기 — 어떤 시간으로 계산했는지(basis)를 함께 받는다
nonisolated struct ShiftChangePreview: Equatable, Sendable {
    /// 계산 조건(basis) — 출근 · 퇴근(분)
    var startMinutes: Int
    var endMinutes: Int
    /// 서버 문구 — 예: 「근무 5시간 그대로 · 22시 이후 1시간」
    var text: String
}

/// 보내는 값 — 근무 id · 바꿀 출근 · 퇴근(분) · 사유
nonisolated struct ShiftChangeRequest: Equatable, Sendable {
    var shiftId: String
    var startMinutes: Int
    var endMinutes: Int
    var reason: String
}

nonisolated enum ShiftChangeEdge: Equatable, Sendable { case start, end }

nonisolated struct ShiftChangeRequestState: Equatable, Sendable {
    var shiftId: String
    /// 예: 「10월 21일 수」 (Asia/Seoul, 서버 문구)
    var dateTitle: String
    var workplaceName: String
    /// 지금 근무(분)
    var startMinutes: Int
    var endMinutes: Int
    /// 엔진 결과. 바꾼 시간과 basis가 같을 때만 보인다. 연결 전은 nil
    var preview: ShiftChangePreview?

    static let headerTitle = "근무 변경 요청"
    static let currentHeader = "지금 근무"
    static let changeHeader = "바꿀 시간"
    static let startTitle = "출근"
    static let endTitle = "퇴근"
    static let previewLabel = "반영되면"
    static let reasonHeader = "사유"
    static let sendTitle = "변경 요청 보내기"
    /// 원문 없음 — 10i · 21c의 「보내는 중」과 같게
    static let sendingTitle = "보내는 중"
    /// 원문 없음 — 9a · C13의 30분 눈금과 같게
    static let stepMinutes = 30
    /// 원문 없음 — 10i와 같게
    static let reasonLimit = 200
    /// 같은 날 범위(자정 넘김은 원문 없음)
    static let dayEnd = 24 * 60

    /// 「17:00 – 22:00」
    var currentRangeText: String { Self.clock(startMinutes) + " \u{2013} " + Self.clock(endMinutes) }

    var shiftAccessibility: String {
        "\(Self.currentHeader), \(dateTitle), \(workplaceName), \(Self.spokenClock(startMinutes))부터 \(Self.spokenClock(endMinutes))까지"
    }

    /// 「18:00」 — 24:00도 그대로(같은 날 끝)
    static func clock(_ minutes: Int) -> String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }

    /// 「18시」 · 「18시 30분」
    static func spokenClock(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)시" : "\(h)시 \(m)분"
    }

    static func rowAccessibilityLabel(_ edge: ShiftChangeEdge) -> String {
        edge == .start ? startTitle : endTitle
    }

    static func clampedReason(_ s: String) -> String {
        s.count > reasonLimit ? String(s.prefix(reasonLimit)) : s
    }

    /// 원문 캡처 값 — 17:00–22:00 → 18:00–23:00, 엔진 결과 basis 일치
    static let sample = ShiftChangeRequestState(
        shiftId: "shift-1021", dateTitle: "10월 21일 수", workplaceName: "종민김밥 본점",
        startMinutes: 17 * 60, endMinutes: 22 * 60,
        preview: ShiftChangePreview(startMinutes: 18 * 60, endMinutes: 23 * 60, text: "근무 5시간 그대로 \u{00B7} 22시 이후 1시간"))
}

/// 사용자가 고친 값. 시작값은 지금 근무(바뀐 게 없음).
nonisolated struct ShiftChangeDraft: Equatable, Sendable {
    var start: Int
    var end: Int
    var reason = ""

    init(start: Int, end: Int, reason: String = "") {
        self.start = start
        self.end = end
        self.reason = reason
    }

    /// 한 칸(30분) 옮긴 값 — 하루 안(0:00–24:00)이고 출근 < 퇴근일 때만. 못 옮기면 nil
    func moved(_ edge: ShiftChangeEdge, by direction: Int) -> (start: Int, end: Int)? {
        let delta = direction * ShiftChangeRequestState.stepMinutes
        switch edge {
        case .start:
            let s = start + delta
            return (s >= 0 && s < end) ? (s, end) : nil
        case .end:
            let e = end + delta
            return (e <= ShiftChangeRequestState.dayEnd && e > start) ? (start, e) : nil
        }
    }

    func canMove(_ edge: ShiftChangeEdge, by direction: Int) -> Bool { moved(edge, by: direction) != nil }

    /// 옮겼으면 true(부모에 알릴 때 쓴다)
    mutating func move(_ edge: ShiftChangeEdge, by direction: Int) -> Bool {
        guard let next = moved(edge, by: direction) else { return false }
        start = next.start
        end = next.end
        return true
    }

    func isChanged(from state: ShiftChangeRequestState) -> Bool {
        start != state.startMinutes || end != state.endMinutes
    }

    var hasReason: Bool { !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// 바뀐 게 없거나 사유가 비면 보낼 수 없다(사유는 원문에 「선택」이 없어 필수로 본다)
    func canSend(for state: ShiftChangeRequestState) -> Bool { isChanged(from: state) && hasReason }

    /// 엔진 결과의 basis가 지금 시간과 같을 때만 문구를 돌려준다. 바뀐 게 없으면 nil
    func previewText(for state: ShiftChangeRequestState) -> String? {
        guard isChanged(from: state), let p = state.preview, p.startMinutes == start, p.endMinutes == end else { return nil }
        return p.text
    }

    func request(for state: ShiftChangeRequestState) -> ShiftChangeRequest {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return ShiftChangeRequest(shiftId: state.shiftId, startMinutes: start, endMinutes: end,
                                  reason: ShiftChangeRequestState.clampedReason(trimmed))
    }
}

/// 보내기는 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
nonisolated struct ShiftChangeLock: Equatable, Sendable {
    private(set) var isSending = false
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
