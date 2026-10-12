// UI-IOS-7b · 21e · 21f · REQ-077 · DEC-002 — 지급 시트 상태(공개 · 복사 · 토스트 · 30초 재가림)
// 시트 내용은 공통 바텀시트 안에서 여러 번 만들어질 수 있어, 상태는 이 객체 하나가 쥔다.
// 전체 계좌번호는 가릴 때 여기서 지운다. 값을 print · 로그에 쓰지 않는다.
import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// 복사: 이 기기에서만 · 60초 뒤 자동 삭제(M9 · M27). 직원별로, 버튼을 눌렀을 때만(DEC-002).
enum PaymentClipboard {
    static let expirySeconds: TimeInterval = 60
    static func copy(_ value: String) {
        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: value]],
            options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(expirySeconds)])
    }
}

@Observable
final class PaymentSendModel {
    let state: PaymentSendState
    /// 보인 상태일 때만 값이 있다(서버 값). 가릴 때 지운다.
    private(set) var fullAccount: String?
    private(set) var accountCopied: Bool
    private(set) var amountCopied = false
    private(set) var toastMessage: String?
    private var revealedAt: Date?
    private var lock = PaymentRevealLock()
    private var maskTask: Task<Void, Never>?
    private var accountCopyTask: Task<Void, Never>?
    private var amountCopyTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    /// M9 복사 확인 유지 시간
    static let copiedHoldSeconds = 1.5

    var isRevealed: Bool { fullAccount != nil }
    var isRevealBusy: Bool { lock.isBusy }
    var canMarkPaid: Bool { PaymentSendState.canMarkPaid(isRevealed: isRevealed) }

    init(state: PaymentSendState) {
        self.state = state
        self.accountCopied = state.initialAccountCopied
        if let full = state.initialFullAccount {
            fullAccount = full
            _ = lock.begin()
            beginMaskTimer(from: Date())
        }
        if state.initialAccountCopied { toastMessage = PaymentSendState.accountCopiedToast }
    }

    deinit { maskTask?.cancel(); accountCopyTask?.cancel(); amountCopyTask?.cancel(); toastTask?.cancel() }

    /// Face ID + 서버 조회는 부모가 한다. 전체 번호를 받으면 보이고, nil이면 가린 채로 둔다.
    func reveal(using onReveal: (_ done: @escaping (String?) -> Void) -> Void) {
        guard lock.begin() else { return }
        onReveal { [weak self] result in
            guard let self else { return }
            if let result, !result.isEmpty {
                fullAccount = result
                lock.finish(success: true)
                beginMaskTimer(from: Date())
            } else {
                lock.finish(success: false)
            }
        }
    }

    /// 앱이 비활성이 되거나 30초가 지나면 — 전체 번호를 지우고 잠금을 푼다
    func mask() {
        maskTask?.cancel(); maskTask = nil
        fullAccount = nil
        revealedAt = nil
        accountCopied = false
        accountCopyTask?.cancel()
        toastTask?.cancel()
        toastMessage = nil
        lock.release()
    }

    func copyAccount() {
        guard let fullAccount else { return } // 계좌 복사는 보인 상태에서만
        PaymentClipboard.copy(fullAccount)
        accountCopied = true
        toastMessage = PaymentSendState.accountCopiedToast
        accountCopyTask?.cancel()
        accountCopyTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.copiedHoldSeconds))
            guard !Task.isCancelled else { return }
            self?.accountCopied = false
        }
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(PumTokens.Duration.toastHold))
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }

    /// 금액은 가린 상태에서도 복사(21e). 토스트 원문이 없어 버튼만 「복사됨」.
    func copyAmount() {
        PaymentClipboard.copy(state.amountCopyText)
        amountCopied = true
        amountCopyTask?.cancel()
        amountCopyTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.copiedHoldSeconds))
            guard !Task.isCancelled else { return }
            self?.amountCopied = false
        }
    }

    private func beginMaskTimer(from start: Date) {
        revealedAt = start
        maskTask?.cancel()
        maskTask = Task { [weak self] in
            while let self, let at = revealedAt, !Task.isCancelled {
                if PaymentRevealPolicy.shouldMask(revealedAt: at, now: Date()) { mask(); return }
                try? await Task.sleep(for: .seconds(PaymentRevealPolicy.remaining(revealedAt: at, now: Date()) + 0.05))
            }
        }
    }
}
