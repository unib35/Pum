// UI-IOS-1m · REQ-074 · REQ-078 · REQ-071 — 급여명세서 화면 데이터
// 금액은 서버(급여 엔진)가 준 정수 원을 그대로 보여 준다. 합계 = 항목 합은 샘플 일관성 확인용(isConsistent)일 뿐,
// 어긋나도 화면에는 서버 값을 쓴다.
import Foundation

nonisolated struct PayslipLine: Equatable, Sendable, Identifiable {
    let id: String
    let label: String
    /// 라벨 옆 작은 회색 계산 근거(예: 「82.5h × 12,000」)
    var note: String?
    /// 양수 원. 공제 줄은 표시할 때 U+2212를 붙인다.
    let amount: Int
}

nonisolated struct PayslipRecord: Equatable, Sendable {
    var monthTitle: String        // 「2026년 10월」
    var workplaceName: String
    var employeeName: String
    var payDateText: String       // 「2026.11.10」
    var workSummary: String       // 「17일 · 82h 30m」 (원문 표기 그대로)
    /// REQ-078: 「입금 완료」 같은 확정 표현 없이 「지급 완료」만 쓴다.
    var statusText: String
    var earnings: [PayslipLine]
    var deductions: [PayslipLine]
    /// 서버가 준 합계 · 실지급액
    var grossTotal: Int
    var deductionTotal: Int
    var netPay: Int
    /// MVP(DEC-033): 월 고르기 · 카카오 · 직원용 안내를 숨기고, 위 공유는 PDF 공유
    var isSolo = false

    var headerCaption: String { "급여명세서 · \(monthTitle)분" }
    var grossText: String { PumFormat.amount(grossTotal) }
    var deductionTotalText: String { PumFormat.deduction(deductionTotal) }
    var netPayText: String { PumFormat.amount(netPay) + "원" }

    /// 확인용: 항목 합 = 합계, 지급 − 공제 = 실지급액
    var isConsistent: Bool {
        earnings.reduce(0) { $0 + $1.amount } == grossTotal
            && deductions.reduce(0) { $0 + $1.amount } == deductionTotal
            && grossTotal - deductionTotal == netPay
    }

    func amountText(_ line: PayslipLine, deduction: Bool) -> String {
        deduction ? PumFormat.deduction(line.amount) : PumFormat.amount(line.amount)
    }

    /// VoiceOver: 「주휴수당 198,000원」 · 공제는 「고용보험 공제 11,000원」
    func accessibilityText(_ line: PayslipLine, deduction: Bool) -> String {
        let base = deduction ? "\(line.label) 공제 \(PumFormat.amount(line.amount))원" : "\(line.label) \(PumFormat.amount(line.amount))원"
        return line.note.map { "\(base), \($0)" } ?? base
    }

    static let sample = PayslipRecord(
        monthTitle: "2026년 10월",
        workplaceName: "종민김밥 본점",
        employeeName: "이종민",
        payDateText: "2026.11.10",
        workSummary: "17일 · 82h 30m",
        statusText: "지급 완료",
        earnings: [
            .init(id: "base", label: "기본급", note: "82.5h × 12,000", amount: 990_000),
            .init(id: "holiday", label: "주휴수당", amount: 198_000),
            .init(id: "overtime", label: "연장근로수당", amount: 30_000),
        ],
        deductions: [
            .init(id: "ei", label: "고용보험", amount: 11_000),
            .init(id: "tax", label: "소득세·지방소득세", amount: 19_000),
        ],
        grossTotal: 1_218_000,
        deductionTotal: 30_000,
        netPay: 1_188_000
    )
}
