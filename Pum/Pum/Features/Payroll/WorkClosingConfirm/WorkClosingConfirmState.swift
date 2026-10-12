// UI-IOS-8c · REQ-028 · REQ-070 — 근무 마감 확인 시트 데이터
// 건수 · 시간 · 금액은 서버가 준 값 그대로. 화면에서 합계를 계산하지 않는다. 금액은 정수 원.
import Foundation

nonisolated struct WorkClosingConfirmState: Equatable, Sendable {
    var month: Int
    var employeeCount: Int
    var recordCount: Int
    var totalWorkText: String      // 서버가 준 총 근무 시간, 예 「382시간 20분」
    var expectedLaborCost: Int     // 서버가 준 예상 인건비(원)
    var problemCount: Int          // 뒤 화면 카드용 — 처리 필요 건수

    var sheetTitle: String { "\(month)월 근무를 마감할까요?" }
    var employeeText: String { "\(employeeCount)명" }
    var recordText: String { "\(recordCount)건" }
    var laborCostText: String { PumFormat.amount(expectedLaborCost) + "원" }
    var checkedTitle: String { "모든 기록을 확인했어요" }
    var checkedSubtitle: String { "\(recordCount)건 \u{00B7} 처리 필요 \(problemCount)건" }
    var lockNoticePrefix: String { "마감 후 \(month)월 기록은 " }
    var lockNoticeStrong: String { "잠기고" }
    var lockNoticeSuffix: String { ", 바꾸려면 정정 절차를 거쳐요" }
    /// 읽기용 — 굵게는 읽기에 영향 없음
    var lockNoticeSpoken: String { lockNoticePrefix + lockNoticeStrong + lockNoticeSuffix }
    var calcNotice: String { "바로 \(month)월 급여 계산이 시작되고 직원에게 알림이 가요" }
    var confirmTitle: String { "\(month)월 근무 마감 \u{00B7} 급여 계산 시작" }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = WorkClosingConfirmState(
        month: 10, employeeCount: 5, recordCount: 76,
        totalWorkText: "382시간 20분", expectedLaborCost: 4_210_000, problemCount: 0)
}
