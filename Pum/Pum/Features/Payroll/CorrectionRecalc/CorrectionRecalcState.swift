// UI-IOS-10g · REQ-075 — 정정 재계산: 차액과 지급 시기를 정하고 확정
// 금액 · 차액 · 내역 문구 · 계산식 설명 · 지급 시기 선택지(기본값 포함)는 모두 엔진(서버) 값.
// 화면은 더하거나 곱하지 않는다. 차액 지급 시기는 노무 검토 미확정(REQ-075) — 화면이 정하지 않는다.
import Foundation

nonisolated enum CorrectionLineDirection: Equatable, Sendable { case increase, decrease }

/// 「바뀐 내역」 한 행 — 금액은 절댓값(원), 부호 · 색은 서버가 준 방향으로
nonisolated struct CorrectionLine: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    /// 계산식 설명(엔진 문구). 없으면 nil
    var detail: String?
    var won: Int
    var direction: CorrectionLineDirection

    var amountText: String {
        switch direction {
        case .increase: "+" + PumFormat.amount(won)
        case .decrease: PumFormat.deduction(won)
        }
    }
    var accessibilityText: String {
        let amount = "\(PumFormat.amount(abs(won)))원"
        let suffix = direction == .increase ? "늘어남" : "공제"
        let head = detail.map { "\(title), \($0), " } ?? "\(title), "
        return "\(head)\(amount) \(suffix)"
    }
}

/// 차액 지급 시기 선택지(서버 값)
nonisolated struct CorrectionPayoutChoice: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var detail: String
}

nonisolated struct CorrectionRecalcState: Equatable, Sendable {
    // 서버 값
    var employeeName: String
    var monthText: String
    var beforeWon: Int
    var afterWon: Int
    var deltaWon: Int
    var lines: [CorrectionLine]
    var choices: [CorrectionPayoutChoice]
    var selectedChoiceID: String
    /// 처리 중 — 두 번 확정 방지
    private(set) var isSending = false

    // MARK: 문구 (원문 그대로)
    static let title = "정정 계산"
    static let changesSection = "바뀐 내역"
    static let payoutSection = "차액 지급"
    static let confirmTitle = "정정 확정"

    init(employeeName: String, monthText: String, beforeWon: Int, afterWon: Int, deltaWon: Int,
         lines: [CorrectionLine], choices: [CorrectionPayoutChoice], selectedChoiceID: String) {
        self.employeeName = employeeName
        self.monthText = monthText
        self.beforeWon = beforeWon
        self.afterWon = afterWon
        self.deltaWon = deltaWon
        self.lines = lines
        self.choices = choices
        self.selectedChoiceID = selectedChoiceID
    }

    var summaryTitle: String { "\(employeeName) \u{00B7} \(monthText) 실지급액" }
    var beforeText: String { PumFormat.amount(beforeWon) }
    var afterText: String { "\(PumFormat.amount(afterWon))원" }
    var deltaText: String {
        deltaWon < 0 ? "\(PumFormat.amount(deltaWon))원" : "+\(PumFormat.amount(deltaWon))원"
    }
    var footnote: String { "\(employeeName)님에게 정정 명세서와 알림이 가요" }

    var summaryAccessibility: String {
        let change = deltaWon < 0 ? "줄어듦" : "늘어남"
        return "\(employeeName) \(monthText) 실지급액, \(beforeText)원에서 \(afterText), \(PumFormat.amount(abs(deltaWon)))원 \(change)"
    }

    func choiceAccessibility(_ choice: CorrectionPayoutChoice) -> String {
        let n = (choices.firstIndex(of: choice) ?? 0) + 1
        return "\(choice.title), \(choice.detail), \(choices.count)개 중 \(n)번째"
    }

    var canConfirm: Bool { choices.contains { $0.id == selectedChoiceID } && !isSending }

    // MARK: 선택 · 확정

    /// 처리 중에는 바꾸지 않는다. 없는 id도 무시.
    mutating func select(_ id: String) {
        guard !isSending, choices.contains(where: { $0.id == id }) else { return }
        selectedChoiceID = id
    }

    /// 확정할 수 있으면 true를 돌려주고 처리 중으로. 이미 처리 중이면 false.
    mutating func beginConfirm() -> Bool {
        guard canConfirm else { return false }
        isSending = true
        return true
    }
    /// 실패일 때만 — 성공이면 되돌릴 수 없으므로 잠긴 채 둔다
    mutating func endConfirm() { isSending = false }
}

extension CorrectionRecalcState {
    /// 디자인 10g 캡처(가짜 데이터)
    static let sample = CorrectionRecalcState(
        employeeName: "김하늘", monthText: "8월",
        beforeWon: 1_062_000, afterWon: 1_084_800, deltaWon: 22_800,
        lines: [
            CorrectionLine(id: "base", title: "기본급", detail: "1시간 \u{00D7} 11,500", won: 11_500, direction: .increase),
            CorrectionLine(id: "over", title: "소정근로 초과 가산", detail: "계약 4.5시간 초과 1시간 \u{00D7} 50%", won: 5_750, direction: .increase),
            CorrectionLine(id: "night", title: "야간 가산", detail: "22시 이후 1시간 \u{00D7} 50%", won: 5_750, direction: .increase),
            CorrectionLine(id: "ei", title: "고용보험", detail: nil, won: 200, direction: .decrease),
        ],
        choices: [
            CorrectionPayoutChoice(id: "withNext", title: "9월 급여에 더해서", detail: "10월 10일 \u{00B7} 명세서에 정정분 따로 표시"),
            CorrectionPayoutChoice(id: "separate", title: "따로 지급", detail: "지급 대기 목록에 추가"),
        ],
        selectedChoiceID: "withNext")
}
