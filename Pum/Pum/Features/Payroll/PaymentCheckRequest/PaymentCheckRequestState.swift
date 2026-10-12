// UI-IOS-21d · REQ-076 · DEC-003 — 입금 확인 요청(사장님) 시트 데이터
// 모든 값은 서버가 준 값 그대로. 금액은 정수 원. 보낸 계좌는 서버가 준 문자열 그대로(가려 오면 가린 값, 충돌 #38).
// 계좌 · 메모는 로그에 남기지 않는다.
import Foundation

/// 월 · 일 · 시 · 분(Asia/Seoul 기준, 서버가 준 값). 화면에서 시간대 변환을 하지 않는다.
nonisolated struct PaymentCheckMoment: Equatable, Sendable {
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int

    /// 「11월 11일 11:05」
    var text: String { "\(month)월 \(day)일 " + String(format: "%d:%02d", hour, minute) }
    /// 읽기용 「11월 11일 11시 5분」
    var spoken: String { "\(month)월 \(day)일 \(hour)시 \(minute)분" }
}

nonisolated struct PaymentCheckRequestState: Equatable, Sendable {
    var employeeName: String
    var avatarColorIndex: Int
    var requestedAt: PaymentCheckMoment
    var memo: String               // 직원이 남긴 메모(원문 그대로)
    var payMonth: Int
    var netPay: Int                // 서버가 준 실지급액(원, 정수)
    var sentAccount: String        // 서버가 준 문자열 그대로(은행 + 계좌, 가려 오면 가린 값)
    var paidAt: PaymentCheckMoment // 지급 완료 처리 시각
    var paidBy: String             // 지급 완료 처리한 사람

    static let dotSeparator = " \u{00B7} "

    var headline: String { "\(employeeName)\(Self.dotSeparator)아직 들어오지 않았어요" }
    var requestSubtitle: String { "\(requestedAt.text)\(Self.dotSeparator)\u{300C}\(memo)\u{300D}" }
    var amountLabel: String { "\(payMonth)월분 실지급액" }
    var amountText: String { PumFormat.amount(netPay) + "원" }
    var accountLabel: String { "보낸 계좌" }
    var paidLabel: String { "지급 완료 처리" }
    var paidSubtitle: String { "\(paidAt.text)\(Self.dotSeparator)\(paidBy)" }
    var revertTitle: String { "지급 대기로" }
    var confirmTitle: String { "보낸 게 맞아요" }
    var confirmingTitle: String { "알리는 중" }
    /// 「\(name)님에게」 — 서버 이름으로 조립
    var notice: String { "\u{300C}보낸 게 맞아요\u{300D}를 누르면 \(employeeName)님에게 다시 확인했다고 알려요" }

    /// VoiceOver 머리 — 「김하늘, 아직 들어오지 않았어요, 11월 11일 11시 5분, 메모 국민은행 앱에서 확인했어요」
    var headSpoken: String { "\(employeeName), 아직 들어오지 않았어요, \(requestedAt.spoken), 메모 \(memo)" }
    var amountSpoken: String { "\(amountLabel), \(amountText)" }
    var paidSpoken: String { "\(paidLabel), \(paidAt.spoken), \(paidBy)" }

    /// 계좌는 숫자를 하나씩 읽게 — 숫자 사이 공백, 하이픈은 쉼, 가림 기호는 「가림」
    var accountSpoken: String { "\(accountLabel), " + Self.digitsSpoken(sentAccount) }

    static func digitsSpoken(_ s: String) -> String {
        var out = ""
        for c in s {
            if c.isNumber { out += "\(c) " }
            else if c == "-" { out = out.trimmingCharacters(in: .whitespaces) + ", " }
            else if "\u{2022}*\u{25CF}".contains(c) { out += "가림 " }
            else { out.append(c) }
        }
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// 시트 열림 바꾸기 허용 — 처리 중에는 닫기(막 누름 · 두 손가락)를 무시한다
    static func allowsSheetChange(to open: Bool, isConfirming: Bool) -> Bool { open || !isConfirming }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = PaymentCheckRequestState(
        employeeName: "김하늘", avatarColorIndex: 1,
        requestedAt: .init(month: 11, day: 11, hour: 11, minute: 5), memo: "국민은행 앱에서 확인했어요",
        payMonth: 10, netPay: 1_062_000, sentAccount: "국민은행 123456-78-901234",
        paidAt: .init(month: 11, day: 10, hour: 14, minute: 20), paidBy: "박민수")
}

/// 「보낸 게 맞아요」 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
nonisolated struct PaymentCheckConfirmLock: Equatable, Sendable {
    private(set) var isConfirming = false
    mutating func begin() -> Bool {
        guard !isConfirming else { return false }
        isConfirming = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isConfirming = false } }
}
