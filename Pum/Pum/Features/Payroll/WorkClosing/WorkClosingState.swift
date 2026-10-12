// UI-IOS-8a · REQ-028 · REQ-070 — 근무 마감 화면 데이터
// 건수 · 시간 · 기간은 서버가 준 값 그대로. 화면에서 합계 · 비율을 계산하지 않는다(막대는 서버 건수로 그리기만).
import Foundation

/// 문제 유형 — 행을 누르면 이 값으로 목록을 연다
nonisolated enum WorkClosingCategory: String, Equatable, Sendable, CaseIterable {
    case needsCheck      // 확인 필요 · 연장 · 지각 · 예정 외
    case missingClockOut // 퇴근 미기록
    case editRequest     // 수정 요청 대기

    var title: String {
        switch self {
        case .needsCheck: "확인 필요 \u{00B7} 연장 \u{00B7} 지각 \u{00B7} 예정 외"
        case .missingClockOut: "퇴근 미기록"
        case .editRequest: "수정 요청 대기"
        }
    }

    /// 「·」는 쉼표로 읽히게
    var spokenTitle: String {
        switch self {
        case .needsCheck: "확인 필요, 연장, 지각, 예정 외"
        default: title
        }
    }
}

nonisolated struct WorkClosingState: Equatable, Sendable {
    var workplaceName: String
    var month: Int
    var periodText: String        // 서버가 준 기간, 예 「10월 1일 – 31일」
    var employeeCount: Int
    var recordCount: Int
    var totalWorkText: String     // 서버가 준 총 근무 시간, 예 「382h 20m」
    var normalCount: Int          // 서버가 준 정상 건수
    var problemCount: Int         // 서버가 준 처리 필요 건수
    var needsCheckCount: Int
    var missingClockOutCount: Int
    var editRequestCount: Int
    var confirmedEmployeeCount: Int   // 「이상 없음」 답한 직원 수
    var confirmRequestTotal: Int      // 확인 요청 대상 직원 수

    var title: String { "\(month)월 근무 마감" }
    var subtitle: String { "\(workplaceName) \u{00B7} \(periodText)" }
    var employeeText: String { "\(employeeCount)명" }
    var recordText: String { "\(recordCount)건" }
    var normalText: String { "정상 \(normalCount)건" }
    var problemText: String { "처리 필요 \(problemCount)건" }
    var barAccessibilityText: String { "\(recordCount)건 중 정상 \(normalCount)건, 처리 필요 \(problemCount)건" }
    var reviewTitle: String { "문제 있는 기록 \(problemCount)건 확인" }
    /// 처리 필요가 0건일 때만 마감할 수 있다(REQ-070)
    var canClose: Bool { problemCount == 0 }
    /// 활성 문구는 원문에 없음 — 「10월 근무 마감」까지만
    var closeTitle: String { canClose ? title : "\(title) \u{00B7} \(problemCount)건 남음" }
    var closeAccessibilityLabel: String { canClose ? title : "\(title), \(problemCount)건 남아 마감할 수 없음" }
    var confirmRequestSubtitle: String { "\(confirmRequestTotal)명 중 \(confirmedEmployeeCount)명 \"이상 없음\" \u{00B7} 선택 단계" }

    func count(of kind: WorkClosingCategory) -> Int {
        switch kind {
        case .needsCheck: needsCheckCount
        case .missingClockOut: missingClockOutCount
        case .editRequest: editRequestCount
        }
    }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = WorkClosingState(
        workplaceName: "종민김밥 본점", month: 10, periodText: "10월 1일 \u{2013} 31일",
        employeeCount: 5, recordCount: 76, totalWorkText: "382h 20m",
        normalCount: 71, problemCount: 5,
        needsCheckCount: 3, missingClockOutCount: 1, editRequestCount: 1,
        confirmedEmployeeCount: 3, confirmRequestTotal: 5)
}

/// 마감 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다(성공이면 잠근 채).
nonisolated struct WorkClosingLock: Equatable, Sendable {
    private(set) var isClosing = false
    /// 마감할 수 있으면 true를 돌려주고 잠근다. 처리 필요가 남았거나 이미 처리 중이면 false.
    mutating func begin(canClose: Bool) -> Bool {
        guard canClose, !isClosing else { return false }
        isClosing = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isClosing = false } }
}
