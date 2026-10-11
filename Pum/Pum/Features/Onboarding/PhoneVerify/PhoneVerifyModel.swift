// UI-IOS-2b · REQ-001 · REQ-011 — 휴대폰 인증 상태(인증번호 6자리 · 남은 시간)
import Foundation

struct PhoneVerifyState: Equatable {
    static let codeLength = 6

    /// 화면에 보이는 번호(서버/이전 화면 값 그대로 — 예: 010-4821-7733)
    var phoneDisplay: String
    /// 숫자만, 최대 6자리
    var code: String = ""
    /// 남은 초(0이면 타이머 정지)
    var remainingSeconds: Int

    /// 디자인 원문: 「482」 입력됨 · 02:41(161초) 남음
    static let sample = PhoneVerifyState(phoneDisplay: "010-4821-7733", code: "482", remainingSeconds: 161)

    /// 실제 진입: 빈 코드
    static func entry(phoneDisplay: String, remainingSeconds: Int) -> PhoneVerifyState {
        PhoneVerifyState(phoneDisplay: phoneDisplay, code: "", remainingSeconds: remainingSeconds)
    }

    /// 입력을 숫자만 · 6자리까지로 다듬는다(붙여넣기 · 자동 채움 포함)
    static func sanitized(_ raw: String) -> String {
        String(raw.filter { $0.isASCII && $0.isNumber }.prefix(codeLength))
    }

    var isComplete: Bool { code.count == Self.codeLength }

    /// 칸 i의 숫자(없으면 nil)
    func digit(at index: Int) -> String? {
        guard index >= 0, index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }

    /// 지금 입력할 칸(다 차면 nil)
    var activeIndex: Int? { isComplete ? nil : code.count }

    var subtitleLead: String { "\(phoneDisplay)으로 보냈어요 · " }

    /// 「02:41 남음」
    var remainingText: String {
        let s = max(0, remainingSeconds)
        return String(format: "%02d:%02d 남음", s / 60, s % 60)
    }

    var accessibilityCodeText: String { "인증번호, 6자리 중 \(code.count)자리 입력됨" }

    mutating func tick() {
        if remainingSeconds > 0 { remainingSeconds -= 1 }
    }
}
