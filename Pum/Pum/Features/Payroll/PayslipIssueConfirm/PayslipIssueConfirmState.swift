// UI-IOS-10e · REQ-074 — 급여명세서 발행 확인 시트 데이터.
// 장수 · 직원 · 금액 · 보내는 때 문구는 서버(10d)가 준 값 그대로. 화면에서 세거나 더하지 않는다.
import Foundation

nonisolated struct PayslipIssueConfirmRow: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int
    var amount: Int   // 실지급액(정수 원, 서버 값)

    var amountText: String { PumFormat.amount(amount) + "원" }
    var accessibilityText: String { "\(name), \(amountText)" }
}

nonisolated struct PayslipIssueConfirmState: Equatable, Sendable {
    var issueCount: Int          // 서버: 발행할 장수
    var subtitle: String         // 서버 「10월분 · 지급 완료 처리할 때 직원에게 보내요」
    var rows: [PayslipIssueConfirmRow]
    var background: PayslipIssueState   // 뒤에 까는 10d 값

    var title: String { "명세서 \(issueCount)장 발행" }
    static let cancelTitle = "취소"
    static let issueTitle = "발행"
    static let issuingTitle = "발행하는 중"
    static let editLabel = "발행 후 수정"
    static let editValue = "정정 명세서로"
    static let recordLabel = "발행 기록"
    static let recordValue = "활동 기록에 남음"

    /// 시트 열림 바꾸기 허용 — 처리 중에는 닫기(막 누름 · 두 손가락)를 무시한다
    static func allowsSheetChange(to open: Bool, isIssuing: Bool) -> Bool { open || !isIssuing }

    /// 원문 캡처 — 10d `.sample`과 맞는 3명(발행 가능한 사람만)
    static let sample: PayslipIssueConfirmState = {
        let bg = PayslipIssueState.sample
        return PayslipIssueConfirmState(
            issueCount: bg.issueCount,
            subtitle: "10월분 \u{00B7} 지급 완료 처리할 때 직원에게 보내요",
            rows: bg.people.filter { $0.missingText == nil }
                .map { PayslipIssueConfirmRow(id: $0.id, name: $0.name, colorIndex: $0.colorIndex, amount: $0.amount) },
            background: bg)
    }()
}
