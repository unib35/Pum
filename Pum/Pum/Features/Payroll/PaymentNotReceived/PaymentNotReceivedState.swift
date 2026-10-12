// UI-IOS-21c · REQ-076 — 「아직 입금 안 됐어요」 시트 데이터 · 초안 · 보내기 잠금
// 사유 선택지 · 문구는 서버 값. 금액은 정수 원. 메모 · 계좌 값은 로그에 남기지 않는다.
import Foundation

nonisolated struct PaymentNotReceivedReason: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
}

nonisolated struct PaymentNotReceivedState: Equatable, Sendable {
    var workplaceName: String
    var month: Int
    var netPay: Int                 // 실지급액(원, 정수)
    var paidAtText: String          // 서버가 준 지급 완료 처리 시각, 예 「11월 10일 14:20」
    var accountText: String         // 서버가 가린 계좌, 예 「국민은행 ••1234」
    var reasons: [PaymentNotReceivedReason]
    /// 지급 완료로 처리된 명세서인가 — false면 화면이 시트를 열지 않는다(21c는 지급 완료 상태에서만)
    var isPaidOut: Bool

    /// 메모 최대 글자 수 — 원문에 제한이 없다(결정 필요). 임시 100자.
    static let memoLimit = 100

    var summaryText: String { "\(workplaceName) \u{00B7} \(month)월분" }
    var netPayText: String { PumFormat.amount(netPay) + "원" }
    var paidTitle: String { "사업주가 지급 완료로 처리했어요" }
    var paidDetail: String { "\(paidAtText) \u{00B7} \(accountText)" }
    var sheetTitle: String { "아직 입금 안 됐어요" }
    var sheetSubtitle: String { "사장님께 확인을 요청해요. 은행 처리에 시간이 걸릴 수도 있어요." }
    var memoLabel: String { "메모 \u{00B7} 선택" }

    /// 첫 번째 사유를 기본 선택으로 둔다(원문 캡처 상태)
    var defaultReasonId: String? { reasons.first?.id }

    /// 시트 열림 허용 — 지급 완료 상태 명세서에서만
    static func canOpenSheet(isPaidOut: Bool) -> Bool { isPaidOut }
    /// 시트 열림 바꾸기 허용 — 보내는 중에는 닫기(막 누름 · 두 손가락 · 취소)를 무시한다
    static func allowsSheetChange(to open: Bool, isSending: Bool) -> Bool { open || !isSending }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = PaymentNotReceivedState(
        workplaceName: "종민김밥 본점", month: 10, netPay: 1_062_000,
        paidAtText: "11월 10일 14:20", accountText: "국민은행 \u{2022}\u{2022}1234",
        reasons: [
            PaymentNotReceivedReason(id: "not_arrived", title: "아직 들어오지 않았어요"),
            PaymentNotReceivedReason(id: "amount_differs", title: "금액이 달라요"),
        ],
        isPaidOut: true)
}

/// 입력 초안 — 사유는 하나만, 메모는 선택이고 글자 수 제한이 있다
nonisolated struct PaymentNotReceivedDraft: Equatable, Sendable {
    private(set) var reasonId: String?
    private(set) var memo: String

    init(reasonId: String? = nil, memo: String = "") {
        self.reasonId = reasonId
        self.memo = Self.limited(memo)
    }

    static func limited(_ text: String) -> String {
        text.count > PaymentNotReceivedState.memoLimit ? String(text.prefix(PaymentNotReceivedState.memoLimit)) : text
    }

    mutating func select(_ id: String) { reasonId = id }
    mutating func setMemo(_ text: String) { memo = Self.limited(text) }

    /// 사유를 골라야 보낼 수 있다
    var canSend: Bool { reasonId != nil }
    /// 서버로 보낼 메모 — 앞뒤 공백을 지우고, 비면 보내지 않는다
    var memoToSend: String? {
        let t = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

/// 보내기는 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다
nonisolated struct PaymentNotReceivedLock: Equatable, Sendable {
    private(set) var isSending = false
    mutating func begin(canSend: Bool) -> Bool {
        guard canSend, !isSending else { return false }
        isSending = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
