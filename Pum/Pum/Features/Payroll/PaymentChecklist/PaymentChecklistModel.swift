// UI-IOS-7a · REQ-076 — 사장님 월급날 지급 체크리스트 데이터. 돈을 보내는 화면이 아니다(은행 앱에서 보낸 뒤 기록만).
// 금액(정수 원) · 건수 · 시각 · 계좌 마스킹은 서버 값 그대로. 합계 · 남은 금액을 화면에서 계산하지 않는다. 막대 비율만 완료 / 전체로 그린다.
import Foundation

/// 지급 대상 직원 한 명
nonisolated struct PaymentChecklistPerson: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int          // 아바타 색(사람 ID 기준 서버 값)
    var bankName: String         // 「국민은행」
    var maskedAccount: String    // 서버가 가린 값 「••••-••-••1234」 — 로그 · 프린트 금지
    var amount: Int              // 실지급액(정수 원, 서버 값)
    /// 지급 완료일 때만 서버 처리 시각 「10:31」. nil이면 지급 대기.
    var paidAtText: String?

    var isPaid: Bool { paidAtText != nil }
    var amountText: String { PumFormat.amount(amount) + "원" }
    /// 화면 계좌 줄 「국민은행 ••••-••-••1234」
    var accountText: String { "\(bankName) \(maskedAccount)" }
    /// 끝 숫자(마스킹 값 뒤쪽 연속 숫자) — VoiceOver용. 마스킹 점은 읽지 않는다.
    var accountLastDigits: String { String(maskedAccount.reversed().prefix(while: \.isNumber).reversed()) }
    var processedText: String? { paidAtText.map { "\($0) 처리" } }

    var accessibilityText: String {
        let account = accountLastDigits.isEmpty ? bankName : "\(bankName) 끝자리 \(accountLastDigits)"
        let status = paidAtText.map { "지급 완료, \($0) 처리" } ?? "지급 대기"
        return "\(name), \(account), \(amountText), \(status)"
    }
}

nonisolated struct PaymentChecklistState: Equatable, Sendable {
    var title: String               // 「10월 급여 지급」
    var payDateText: String         // 「지급일 11월 10일 (화) · 오늘」
    var statusBadgeText: String     // 「지급 중」
    var totalAmount: Int            // 서버 합계(원)
    var employeeCount: Int          // 서버 값
    var paidCount: Int              // 서버 값
    var paidAmount: Int             // 서버 값
    var remainingCount: Int         // 서버 값
    var remainingAmount: Int        // 서버 값
    var pending: [PaymentChecklistPerson]
    var paid: [PaymentChecklistPerson]

    var totalText: String { PumFormat.amount(totalAmount) + "원" }
    var employeeCountText: String { "직원 \(employeeCount)명" }
    var paidSummaryText: String { "지급 완료 \(paidCount) / \(employeeCount) · \(PumFormat.amount(paidAmount))원" }
    var remainingSummaryText: String { "남은 \(remainingCount)명 · \(PumFormat.amount(remainingAmount))원" }
    /// 진행 막대 비율(그리기 전용). 전체 0이면 0.
    var progress: Double { employeeCount > 0 ? min(1, max(0, Double(paidCount) / Double(employeeCount))) : 0 }
    var pendingHeaderText: String { "지급 대기 \(pending.count)" }
    var paidHeaderText: String { "지급 완료 \(paid.count)" }
    var summaryAccessibilityText: String {
        "\(payDateText), \(statusBadgeText), 총 \(totalText), \(employeeCountText), \(paidSummaryText), \(remainingSummaryText)"
    }

    static let footnote = "송금은 은행 앱에서 해요. 이 화면은 보낼 정보 복사와 지급 기록만 도와줘요."

    /// 원문 값(가짜 데이터)
    static let sample = PaymentChecklistState(
        title: "10월 급여 지급",
        payDateText: "지급일 11월 10일 (화) · 오늘",
        statusBadgeText: "지급 중",
        totalAmount: 4_210_000,
        employeeCount: 4,
        paidCount: 2,
        paidAmount: 2_268_000,
        remainingCount: 2,
        remainingAmount: 1_942_000,
        pending: [
            .init(id: "e-hanul", name: "김하늘", colorIndex: 1, bankName: "국민은행", maskedAccount: "••••-••-••1234", amount: 1_062_000, paidAtText: nil),
            .init(id: "e-seojun", name: "박서준", colorIndex: 3, bankName: "신한은행", maskedAccount: "••••-•••-••5521", amount: 880_000, paidAtText: nil),
        ],
        paid: [
            .init(id: "e-jongmin", name: "이종민", colorIndex: 0, bankName: "카카오뱅크", maskedAccount: "••••-••-••4821", amount: 1_188_000, paidAtText: "10:31"),
            .init(id: "e-yuna", name: "최유나", colorIndex: 2, bankName: "우리은행", maskedAccount: "••••-•••-••0937", amount: 1_080_000, paidAtText: "10:24"),
        ]
    )
}
