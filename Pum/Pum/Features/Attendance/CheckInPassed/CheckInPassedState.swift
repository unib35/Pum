// UI-IOS-10t · REQ-022 — 출근 판정 통과(QR + 위치) 결과 데이터
// 시각 · 거리 · 허용 · 예정 · 「n분 일찍」은 서버(판정) 값 그대로 — 화면에서 계산하지 않는다.
// 출근 시각은 서버가 Asia/Seoul로 기록한 하루 안의 분 값을 「HH:mm」으로만 바꾼다.
import Foundation

nonisolated struct CheckInPassedCheck: Equatable, Sendable, Identifiable {
    enum Kind: Equatable, Sendable { case qr, location }
    var kind: Kind
    /// 서버가 준 근거 값
    var workplaceName: String = ""
    var distanceMeters: Int = 0
    var allowedMeters: Int = 0

    var id: Kind { kind }
    var title: String { kind == .qr ? "QR 확인" : "위치 확인" }
    var detail: String {
        switch kind {
        case .qr: "\(workplaceName) 출근 QR"
        case .location: "사업장에서 \(distanceMeters)m \u{00B7} 허용 \(allowedMeters)m"
        }
    }
    /// 「QR 확인, 종민김밥 본점 출근 QR, 완료」
    var accessibilityText: String { "\(title), \(detail), 완료" }
}

nonisolated struct CheckInPassedState: Equatable, Sendable {
    var workplaceName: String
    var dateTitle: String
    /// 통과한 확인 목록(서버 값). 위치만 · QR만 방식이면 한 행만 온다.
    var checks: [CheckInPassedCheck]
    /// 서버가 기록한 출근 · 예정 근무 시각(하루 안의 분)
    var clockInMinute: Int
    var plannedStartMinute: Int
    var plannedEndMinute: Int
    /// 서버 판정 문구(예: 「3분 일찍」). 없으면 붙이지 않는다.
    var timingNote: String?
    /// 퇴근 방법 안내 값(예: 「같은 QR을 다시 스캔」)
    var clockOutHow: String

    static func clock(_ minute: Int) -> String { String(format: "%02d:%02d", (minute / 60) % 24, minute % 60) }

    static let screenTitle = "출근"
    static let headline = "출근했어요"
    static let sectionTitle = "확인"
    static let doneTitle = "확인"
    static let clockInLabel = "출근 시각"
    static let clockOutTitle = "퇴근할 때"

    var subtitle: String { "\(workplaceName) \u{00B7} \(dateTitle)" }
    var clockInText: String { Self.clock(clockInMinute) }
    var clockInAccessibility: String { "출근 시각 \(PumTimeWheelMath.spokenText(clockInMinute))" } // 「오전 9시 57분」 — C13과 같은 읽기
    var plannedLine: String {
        let base = "예정 \(PumFormat.timeRange(Self.clock(plannedStartMinute), Self.clock(plannedEndMinute)))"
        guard let timingNote, !timingNote.isEmpty else { return base }
        return base + " \u{00B7} " + timingNote
    }
    var clockOutNotice: String { "예정 퇴근 \(Self.clock(plannedEndMinute))에 알려드려요" }

    /// 디자인 10t 예시 값(가짜 데이터)
    static let sample = CheckInPassedState(
        workplaceName: "종민김밥 본점", dateTitle: "10월 6일 화",
        checks: [
            CheckInPassedCheck(kind: .qr, workplaceName: "종민김밥 본점"),
            CheckInPassedCheck(kind: .location, distanceMeters: 18, allowedMeters: 100),
        ],
        clockInMinute: 9 * 60 + 57, plannedStartMinute: 10 * 60, plannedEndMinute: 15 * 60,
        timingNote: "3분 일찍", clockOutHow: "같은 QR을 다시 스캔"
    )
}
