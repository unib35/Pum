// UI-IOS-7c · REQ-076 — 지급 완료 확인 다이얼로그 데이터
// 받는 사람 · 계좌(서버가 가린 값) · 금액은 서버 값 그대로. 금액은 정수 원. 로그에 남기지 않는다.
import Foundation

nonisolated struct PaymentDoneConfirmState: Equatable, Sendable {
    var recipientName: String
    var maskedAccountText: String   // 서버가 가린 값, 예 「국민 ••••1234」
    var amount: Int                 // 원

    var title: String { "지급 완료로 처리할까요?" }
    var recipientKey: String { "받는 사람" }
    var accountKey: String { "계좌" }
    var amountKey: String { "금액" }
    var amountText: String { PumFormat.amount(amount) + "원" }
    var noticeLine1: String { "은행 앱에서 실제 송금이" }
    var noticeLine2: String { "끝났는지 확인해주세요." }
    /// 줄바꿈 없이 읽기용
    var noticeSpoken: String { noticeLine1 + " " + noticeLine2 }
    var cancelTitle: String { "취소" }
    var confirmTitle: String { "지급 완료" }
    /// 원문에 없음 — 처리 중 버튼 글자
    var processingTitle: String { "처리하는 중" }

    /// 읽기용 계좌 — 마스킹 점은 읽지 않는다: 「국민 끝자리 1234」
    var accountSpoken: String {
        let parts = maskedAccountText.split(separator: " ", maxSplits: 1).map(String.init)
        let strip: (String) -> String = { $0.replacingOccurrences(of: "\u{2022}", with: "").replacingOccurrences(of: "-", with: "") }
        guard parts.count == 2 else { return strip(maskedAccountText) }
        return "\(parts[0]) 끝자리 \(strip(parts[1]))"
    }

    /// 처리 중에는 막 누름 · 두 손가락 닫기를 무시한다
    static func allowsDismiss(isProcessing: Bool) -> Bool { !isProcessing }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = PaymentDoneConfirmState(recipientName: "김하늘", maskedAccountText: "국민 \u{2022}\u{2022}\u{2022}\u{2022}1234", amount: 1_062_000)
}
