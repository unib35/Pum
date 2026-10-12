// UI-IOS-8b · REQ-028 · REQ-070 — 사장님 문제 기록 처리 화면 데이터
// 문구 · 금액 · 시각 · 건수는 서버가 준 값 그대로. 화면에서 계산하지 않는다(막대 폭만 처리/전체).
// 처리에 성공하면 서버의 새 상태로 다시 그린다 — 화면이 행을 직접 옮기지 않는다.
import Foundation

/// 남은 문제 기록의 종류 — 배지 색과 버튼 두 개가 이 값으로 정해진다
nonisolated enum WorkClosingProblemKind: Equatable, Sendable {
    case missingClockOut // 퇴근 미기록: 직접 입력 · 확인 요청
    case overtime        // 연장: 수정 · 인정
    case offSchedule     // 예정 외 근무: 거절 · 인정
}

/// 서버에 보내는 처리 동작. 「직접 입력」 · 「수정」은 입력 화면을 여는 onEdit로 분리한다.
nonisolated enum WorkClosingProblemAction: Equatable, Sendable {
    case confirmRequest // 확인 요청
    case approve        // 인정
    case reject         // 거절
}

nonisolated struct WorkClosingProblemItem: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int
    var dateText: String          // 「10/28 화」
    var dateSpokenText: String    // 「10월 28일 화요일」
    var kind: WorkClosingProblemKind
    var badgeText: String         // 「퇴근 미기록」 · 「연장 1:02」 · 「예정 외 근무」
    var detailText: String        // 서버가 준 설명 줄

    /// 왼쪽 버튼 글자
    var leadingTitle: String {
        switch kind {
        case .missingClockOut: "직접 입력"
        case .overtime: "수정"
        case .offSchedule: "거절"
        }
    }
    /// 거절이면 서버 처리, 나머지(직접 입력 · 수정)는 입력 화면(nil)
    var leadingAction: WorkClosingProblemAction? { kind == .offSchedule ? .reject : nil }
    var trailingTitle: String { kind == .missingClockOut ? "확인 요청" : "인정" }
    var trailingAction: WorkClosingProblemAction { kind == .missingClockOut ? .confirmRequest : .approve }

    /// 「·」 · 「→」는 쉼표 · 「에서」로 읽히게
    /// 버튼 음성 안내 앞말 「박서준 10월 28일 화요일」
    var buttonContext: String { "\(name) \(dateSpokenText)" }
    var accessibilityText: String {
        let spoken = detailText
            .replacingOccurrences(of: " \u{00B7} ", with: ", ")
            .replacingOccurrences(of: " \u{2192} ", with: "에서 ")
        return "\(name), \(dateSpokenText), \(badgeText), \(spoken)"
    }
}

nonisolated struct WorkClosingResolvedItem: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int
    var dateText: String
    var dateSpokenText: String
    var resultText: String        // 「지각 15분 · 확인」

    var nameDateText: String { "\(name) \u{00B7} \(dateText)" }
    var accessibilityText: String {
        "\(name), \(dateSpokenText), \(resultText.replacingOccurrences(of: " \u{00B7} ", with: ", "))"
    }
}

nonisolated struct WorkClosingProblemsState: Equatable, Sendable {
    var totalCount: Int           // 처리 필요 전체 건수(서버)
    var doneCount: Int            // 처리된 건수(서버)
    var remaining: [WorkClosingProblemItem]
    var resolved: [WorkClosingResolvedItem]
    var normalCount: Int          // 정책에 따라 이미 확정된 정상 기록

    var title: String { "처리 필요 \(totalCount)건" }
    var progressText: String { "\(doneCount) / \(totalCount)" }
    var progressAccessibilityText: String { "\(totalCount)건 중 \(doneCount)건 처리" }
    /// 막대 폭만 처리/전체
    var progress: Double { totalCount > 0 ? min(1, Double(doneCount) / Double(totalCount)) : 0 }
    var remainingHeader: String { "남은 \(remaining.count)건" }
    var resolvedHeader: String { "처리됨 \(resolved.count)건" }
    var footnote: String { "정상 기록 \(normalCount)건은 정책에 따라 이미 확정돼 있어요." }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = WorkClosingProblemsState(
        totalCount: 5, doneCount: 2,
        remaining: [
            .init(id: "p1", name: "박서준", colorIndex: 3, dateText: "10/28 화", dateSpokenText: "10월 28일 화요일",
                  kind: .missingClockOut, badgeText: "퇴근 미기록", detailText: "09:03 출근 \u{00B7} 예정 퇴근 15:00"),
            .init(id: "p2", name: "김하늘", colorIndex: 1, dateText: "10/24 금", dateSpokenText: "10월 24일 금요일",
                  kind: .overtime, badgeText: "연장 1:02", detailText: "예정 22:00 \u{2192} 23:02 \u{00B7} +12,400원"),
            .init(id: "p3", name: "정우진", colorIndex: 4, dateText: "10/22 수", dateSpokenText: "10월 22일 수요일",
                  kind: .offSchedule, badgeText: "예정 외 근무", detailText: "13:00\u{2013}17:00 \u{00B7} 48,000원"),
        ],
        resolved: [
            .init(id: "r1", name: "최유나", colorIndex: 2, dateText: "10/15 수", dateSpokenText: "10월 15일 수요일",
                  resultText: "지각 15분 \u{00B7} 확인"),
            .init(id: "r2", name: "김하늘", colorIndex: 1, dateText: "9/30 화", dateSpokenText: "9월 30일 화요일",
                  resultText: "수정 요청 승인 \u{00B7} 22:30"),
        ],
        normalCount: 71)
}

/// 행 처리 잠금 — 누른 행만 잠그고(그 행의 두 버튼 모두), 실패일 때만 푼다. 다른 행은 영향 없음.
nonisolated struct WorkClosingRowLock: Equatable, Sendable {
    private(set) var processing: Set<String> = []
    func isLocked(_ id: String) -> Bool { processing.contains(id) }
    /// 처음 누르면 true를 돌려주고 잠근다. 이미 처리 중이면 false.
    mutating func begin(_ id: String) -> Bool { processing.insert(id).inserted }
    mutating func finish(_ id: String, success: Bool) { if !success { processing.remove(id) } }
    /// 서버 새 상태가 오면 잠금을 푼다 — 성공한 행은 처리됨으로 옮겨 갔거나(확인 요청처럼) 남아도 다시 누를 수 있어야 한다
    mutating func reset() { processing.removeAll() }
}
