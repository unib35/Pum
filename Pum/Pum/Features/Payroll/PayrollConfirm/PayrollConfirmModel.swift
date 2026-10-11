// UI-IOS-1v · REQ-107 — 급여 확정 확인 시트 데이터
// 금액 · 건수 · 지급일 · 알림 시각은 서버(엔진)가 준 값 그대로. 화면에서 계산하지 않는다.
import Foundation

nonisolated struct PayrollConfirmNote: Equatable, Sendable {
    let head: String
    let bold: String
    let tail: String
    var text: String { head + bold + tail }
}

nonisolated struct PayrollConfirmState: Equatable, Sendable {
    var year: Int
    var month: Int              // 10 → 「10월」
    var totalAmount: Int        // 서버가 준 원
    var employeeCount: Int
    var recordCount: Int        // 사용된 근무기록(건)
    var payDayLabel: String     // 서버가 준 지급일, 예 「11월 10일」
    var reminderLabel: String   // 서버가 준 알림 시각, 예 「11월 9일 오전 9시」
    /// 토글 — 원문 캡처는 둘 다 켜짐(급여명세서 보내기는 사장님이 끌 수 있다)
    var sendsPayslip = true
    var remindsPayDay = true
    /// 확정 누른 뒤 처리 중(M26) — 기본 false
    var isConfirming = false

    var yearMonthTitle: String { "\(year)년 \(month)월" }
    var sheetTitle: String { "\(month)월 급여를 확정할까요?" }
    var amountText: String { PumFormat.amount(totalAmount) + "원" }
    var expectedTitle: String { "\(month)월 총 지급 예정" }
    var checkedTitle: String { "근무기록 \(recordCount)건 모두 확인됐어요" }
    var checkedSubtitle: String { "이제 급여를 확정할 수 있어요" }
    var summaryLeft: String { "직원 \(employeeCount)명 \u{00B7} 근무기록 \(recordCount)건" }
    var summaryRight: String { "지급일 \(payDayLabel)" }

    /// 점 목록 — 원문 그대로(굵은 부분 따로)
    var notes: [PayrollConfirmNote] {
        [PayrollConfirmNote(head: "확정하면 사용된 근무기록 \(recordCount)건이 기준 데이터로 ", bold: "고정", tail: "돼요"),
         PayrollConfirmNote(head: "이후 변경이 필요하면 기록을 바꾸지 않고 ", bold: "정정 내역", tail: "으로 남아요")]
    }

    static let payslipTitle = "직원에게 급여명세서 보내기"
    static let payslipSubtitle = "카카오 알림톡 \u{00B7} 앱 알림"
    static let reminderTitle = "지급 예정일 알림 받기"
    /// 「·」는 쉼표로 읽히게
    var payslipAccessibilityLabel: String { "\(Self.payslipTitle), 카카오 알림톡, 앱 알림" }
    var reminderAccessibilityLabel: String { "\(Self.reminderTitle), \(reminderLabel)" }

    /// 원문 캡처(시트 열림 · 두 토글 켜짐) — 가짜 예시 값
    static let sample = PayrollConfirmState(
        year: 2026, month: 10, totalAmount: 4_210_000, employeeCount: 4, recordCount: 68,
        payDayLabel: "11월 10일", reminderLabel: "11월 9일 오전 9시")
}
