// UI-IOS-15e · REQ-002 — 초대 코드가 틀렸을 때의 상태. 남은 횟수는 서버 값(화면이 세지 않는다).
import SwiftUI

nonisolated struct InviteCodeRetryState: Equatable, Sendable {
    static let codeLength = 6

    var code: String
    /// 서버가 준 남은 시도 횟수. 0이면 10분 잠금(잠금 화면 디자인 없음 — 확인 비활성만)
    var remainingAttempts: Int?
    /// 틀린 코드 표시(빨간 테두리 · 오류 문구)
    var isError: Bool
    var isConfirming = false

    init(code: String = "", remainingAttempts: Int? = nil, isError: Bool = false, isConfirming: Bool = false) {
        self.code = PumCodeField.sanitized(code, length: Self.codeLength, characters: .alphanumeric)
        self.remainingAttempts = remainingAttempts
        self.isError = isError
        self.isConfirming = isConfirming
    }

    /// 디자인 원문: 8F3K2P · 4번 남음 · 오류 표시
    static let sample = InviteCodeRetryState(code: "8F3K2P", remainingAttempts: 4, isError: true)

    var isComplete: Bool { code.count == Self.codeLength }
    var isLocked: Bool { remainingAttempts == 0 }
    var canConfirm: Bool { isComplete && !isLocked && !isConfirming }

    /// 「코드가 맞지 않아요 · 4번 더 입력할 수 있어요」 — 틀림 표시 중이고 횟수를 알 때만 횟수를 붙인다
    var errorText: String? {
        guard isError else { return nil }
        guard let n = remainingAttempts, n > 0 else { return "코드가 맞지 않아요" }
        return "코드가 맞지 않아요 · \(n)번 더 입력할 수 있어요"
    }

    /// 코드를 고치기 시작하면 빨간 표시와 문구를 지운다(새로 확인하기 전까지)
    mutating func codeChanged(to new: String) {
        guard new != code else { return }
        code = new
        isError = false
    }

    mutating func beginConfirm() -> Bool {
        guard canConfirm else { return false }
        isConfirming = true
        return true
    }

    mutating func failConfirm() { isConfirming = false }
}
