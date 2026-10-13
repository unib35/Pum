// UI-IOS-20h · REQ-007 · REQ-074 — 명세서 보내기: 앱 직원은 앱 알림, 앱 없는 직원은 알림톡(안 되면 문자) + PDF
// 모든 값은 서버가 준 그대로. 금액은 정수(원), 전화번호는 서버가 가린 문자열을 그대로 보여 준다(풀거나 가리지 않음).
import Foundation

nonisolated struct PayslipSendDirectState: Equatable, Sendable {
    /// 받는 직원 한 명
    nonisolated struct Recipient: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        let initial: String      // 서버가 준 아바타 글자(첫 글자)
        let methodText: String   // 서버 문구 예 「앱 알림」 · 「알림톡 · 010-****-2048」
        let netPay: Int          // 실지급액(원)
        let hasApp: Bool         // 앱 없는 직원이면 PDF 카드가 따로 나온다

        var amountText: String { PumFormat.amount(netPay) + "원" }
        /// 읽기: 「김민지, 알림톡 · 010-****-2048, 556,360원」
        var spokenText: String { "\(name), \(methodText), \(amountText)" }
        var pdfTitle: String { "\(name) 명세서 PDF" }
        var pdfSpoken: String { "\(name) 명세서 PDF 공유" }
    }

    let monthText: String      // 서버 값 예 「2026년 9월분 · 지급일 10월 10일」
    let recipients: [Recipient]
    let sendCount: Int         // 서버가 준 보낼 건수

    var title: String { "명세서 보내기" }
    var countText: String { "\(recipients.count)명" }
    var sendTitle: String { "명세서 \(sendCount)건 보내기" }
    /// 앱 없는 직원마다 PDF 카드 한 장 — 없으면 빈 목록
    var pdfRecipients: [Recipient] { recipients.filter { !$0.hasApp } }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = PayslipSendDirectState(
        monthText: "2026년 9월분 \u{00B7} 지급일 10월 10일",
        recipients: [
            Recipient(id: "haneul", name: "김하늘", initial: "하", methodText: "앱 알림", netPay: 972_345, hasApp: true),
            Recipient(id: "jongmin", name: "이종민", initial: "종", methodText: "앱 알림", netPay: 1_118_610, hasApp: true),
            Recipient(id: "seojun", name: "박서준", initial: "서", methodText: "앱 알림", netPay: 917_660, hasApp: true),
            Recipient(id: "minji", name: "김민지", initial: "민", methodText: "알림톡 \u{00B7} 010-****-2048", netPay: 556_360, hasApp: false),
        ],
        sendCount: 4)

    /// 앱 없는 직원이 없을 때 — PDF 카드 없음
    static let allApp = PayslipSendDirectState(
        monthText: "2026년 9월분 \u{00B7} 지급일 10월 10일",
        recipients: Array(sample.recipients.prefix(3)), sendCount: 3)
}

/// 처리 중 잠금 — 보내기는 한 번만. 성공이면 잠근 채(실패일 때만 풀림).
nonisolated struct PayslipSendDirectLock: Equatable, Sendable {
    private(set) var isSending = false
    private(set) var isSent = false

    var isLocked: Bool { isSending || isSent }

    mutating func beginSend() -> Bool {
        guard !isLocked else { return false }
        isSending = true
        return true
    }
    mutating func finishSend(success: Bool) {
        isSending = false
        if success { isSent = true }
    }
}
