// UI-IOS-7b · 21e · 21f · REQ-076 · REQ-077 · DEC-002 — 직원별 지급 시트 데이터와 규칙
// 돈을 보내는 화면이 아니다 — 계좌번호 · 금액을 복사하고, 은행 앱에서 보낸 뒤 지급 완료로 기록만 한다.
// 전체 계좌번호는 서버 값이고 Face ID 성공 뒤에만 받는다. 금액은 정수 원. 계좌 · 금액을 로그에 쓰지 않는다.
import Foundation

nonisolated struct PaymentSendState: Equatable, Sendable {
    var name: String
    var colorIndex: Int            // 아바타 색(사람 ID 기준 서버 값)
    var month: Int
    var workHoursText: String      // 서버 값 「74시간」
    var hourlyWage: Int            // 정수 원
    var bankName: String
    var accountHolder: String
    var maskedAccount: String      // 서버가 가린 값 「••••••-••-••1234」
    var amount: Int                // 실지급액(정수 원, 서버 값)
    /// 캡처 · 미리보기용 초기 공개 값(보인 상태). nil이면 가린 상태로 시작한다. 실제로는 Face ID 뒤 서버가 준다.
    var initialFullAccount: String?
    /// 캡처용: 계좌번호를 방금 복사한 상태(「복사됨」 · 토스트)로 시작
    var initialAccountCopied = false

    var titleText: String { "\(name) \u{00B7} \(month)월 급여" }
    var subtitleText: String { "\(workHoursText) \u{00B7} 시급 \(PumFormat.amount(hourlyWage))원 \u{00B7} 지급 대기" }
    var amountText: String { PumFormat.amount(amount) + "원" }
    var bankLineText: String { "\(bankName) \u{00B7} 예금주 \(accountHolder)" }
    /// 금액 복사 값 — 숫자만(콤마 · 원 제외). 원문에 형식이 없어 정함.
    var amountCopyText: String { String(amount) }
    /// 끝 숫자(마스킹 값 뒤쪽 연속 숫자) — VoiceOver용
    var accountLastDigits: String { String(maskedAccount.reversed().prefix(while: \.isNumber).reversed()) }
    var maskedAccessibilityText: String { "계좌번호, 끝자리 \(accountLastDigits), 가려짐" }

    /// VoiceOver: 숫자를 하나씩 읽게 띄어 쓴다. 하이픈은 쉼표로.
    static func spokenAccount(_ full: String) -> String {
        full.map { $0 == "-" ? "," : String($0) }.joined(separator: " ")
    }

    static let accountCopiedToast = "계좌번호를 복사했어요. 은행 앱에 붙여넣어 주세요."
    static let markPaidTitle = "송금했어요 \u{00B7} 지급 완료 처리"
    static let clipboardNotice = "복사한 정보는 60초 후 클립보드에서 지워져요"

    /// 지급 완료 처리는 계좌번호를 확인(보인 상태)한 뒤에만
    static func canMarkPaid(isRevealed: Bool) -> Bool { isRevealed }

    /// 7b 원문 — 보인 상태 · 계좌번호 복사됨(가짜 예시 값)
    static let sample = PaymentSendState(
        name: "김하늘", colorIndex: 1, month: 10, workHoursText: "74시간", hourlyWage: 11_500,
        bankName: "국민은행", accountHolder: "김하늘", maskedAccount: "••••••-••-••1234",
        amount: 1_062_000, initialFullAccount: "123456-78-901234", initialAccountCopied: true)

    /// 21e 원문 — 가린 상태
    static let masked: PaymentSendState = {
        var s = PaymentSendState.sample
        s.initialFullAccount = nil
        s.initialAccountCopied = false
        return s
    }()
}

/// 보인 뒤 30초가 지나면 다시 가린다(M27).
nonisolated enum PaymentRevealPolicy {
    static let visibleSeconds: TimeInterval = 30
    /// 공개 시각 + 30초 ≤ 지금 → 가림
    static func shouldMask(revealedAt: Date, now: Date) -> Bool {
        revealedAt.addingTimeInterval(visibleSeconds) <= now
    }
    /// 가릴 때까지 남은 초(0 이상)
    static func remaining(revealedAt: Date, now: Date) -> TimeInterval {
        max(0, revealedAt.addingTimeInterval(visibleSeconds).timeIntervalSince(now))
    }
}

/// 「Face ID로 보기」 한 번만 — 누르는 즉시 잠그고, 실패 · 취소면 푼다. 보인 동안은 잠근 채, 다시 가리면 푼다.
nonisolated struct PaymentRevealLock: Equatable, Sendable {
    private(set) var isBusy = false
    mutating func begin() -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isBusy = false } }
    mutating func release() { isBusy = false }
}
