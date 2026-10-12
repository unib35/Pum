// UI-IOS-7b · 21e · 21f · REQ-077 · DEC-002 — 지급 시트 문구 · 30초 재가림 · 한 번만 잠금 · 송금 버튼 · 복사 값
import Testing
import SwiftUI
import Foundation
@testable import Pum

struct PaymentSendTests {
    let s = PaymentSendState.sample

    @Test func 원문_문구() {
        #expect(s.titleText == "김하늘 \u{00B7} 10월 급여")
        #expect(s.subtitleText == "74시간 \u{00B7} 시급 11,500원 \u{00B7} 지급 대기")
        #expect(s.amountText == "1,062,000원")
        #expect(s.bankLineText == "국민은행 \u{00B7} 예금주 김하늘")
        #expect(PaymentSendState.accountCopiedToast == "계좌번호를 복사했어요. 은행 앱에 붙여넣어 주세요.")
        #expect(PaymentSendState.markPaidTitle == "송금했어요 \u{00B7} 지급 완료 처리")
        #expect(PaymentSendState.clipboardNotice == "복사한 정보는 60초 후 클립보드에서 지워져요")
    }

    @Test func 가린_표시_문자열() {
        #expect(s.maskedAccount == "••••••-••-••1234")
        #expect(s.accountLastDigits == "1234")
        #expect(s.maskedAccessibilityText == "계좌번호, 끝자리 1234, 가려짐")
        #expect(!s.maskedAccessibilityText.contains("•"))
        #expect(PaymentSendState.spokenAccount("123456-78-901234") == "1 2 3 4 5 6 , 7 8 , 9 0 1 2 3 4")
    }

    @Test func 금액_복사_문자열은_숫자만() {
        #expect(s.amountCopyText == "1062000")
        #expect(!s.amountCopyText.contains(",") && !s.amountCopyText.contains("원"))
    }

    @Test func 상태별_초기값() {
        #expect(PaymentSendState.sample.initialFullAccount != nil)
        #expect(PaymentSendState.sample.initialAccountCopied)
        #expect(PaymentSendState.masked.initialFullAccount == nil)
        #expect(!PaymentSendState.masked.initialAccountCopied)
    }

    @Test func 송금_버튼은_보인_상태에서만_활성() {
        #expect(PaymentSendState.canMarkPaid(isRevealed: true))
        #expect(!PaymentSendState.canMarkPaid(isRevealed: false))
        #expect(PaymentSendModel(state: .masked).canMarkPaid == false)
        #expect(PaymentSendModel(state: .sample).canMarkPaid == true)
    }

    @Test func 공개_30초_뒤_다시_가림() {
        let at = Date(timeIntervalSince1970: 1_000)
        #expect(PaymentRevealPolicy.visibleSeconds == 30)
        #expect(!PaymentRevealPolicy.shouldMask(revealedAt: at, now: at))
        #expect(!PaymentRevealPolicy.shouldMask(revealedAt: at, now: at.addingTimeInterval(29.9)))
        #expect(PaymentRevealPolicy.shouldMask(revealedAt: at, now: at.addingTimeInterval(30)))
        #expect(PaymentRevealPolicy.shouldMask(revealedAt: at, now: at.addingTimeInterval(31)))
        #expect(PaymentRevealPolicy.remaining(revealedAt: at, now: at.addingTimeInterval(10)) == 20)
        #expect(PaymentRevealPolicy.remaining(revealedAt: at, now: at.addingTimeInterval(99)) == 0)
    }

    @Test func 공개_한_번만_잠금() {
        var lock = PaymentRevealLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish(success: false) // 실패 · 취소면 푼다
        let third = lock.begin()
        #expect(third)
        lock.finish(success: true)  // 성공이면 보이는 동안 잠근 채
        let fourth = lock.begin()
        #expect(!fourth)
        lock.release()              // 다시 가리면 푼다
        let fifth = lock.begin()
        #expect(fifth)
    }

    @Test func 공개는_부모가_준_번호로만_보이고_실패면_가린_채() {
        let m = PaymentSendModel(state: .masked)
        m.reveal { done in done(nil) }
        #expect(!m.isRevealed && !m.isRevealBusy)
        m.reveal { done in done("123456-78-901234") }
        #expect(m.isRevealed && m.fullAccount == "123456-78-901234")
        m.mask()
        #expect(!m.isRevealed && m.fullAccount == nil && !m.isRevealBusy)
    }

    @Test func 가린_상태에서는_계좌_복사_안_됨() {
        let m = PaymentSendModel(state: .masked)
        m.copyAccount()
        #expect(!m.accountCopied && m.toastMessage == nil)
    }

    @Test @MainActor func 가린_뒤_늦게_온_공개_결과는_버린다() {
        let model = PaymentSendModel(state: .masked)
        var pending: ((String?) -> Void)?
        model.reveal { done in pending = done }
        model.mask() // 인증 기다리는 중 시트 닫힘 · 백그라운드
        pending?("123456-78-901234")
        #expect(!model.isRevealed)
        #expect(!model.isRevealBusy)
    }

    @Test @MainActor func 전체_번호는_모델_한_곳에만() {
        let model = PaymentSendModel(state: .sample)
        #expect(model.state.initialFullAccount == nil)
        #expect(model.isRevealed)
        model.mask()
        #expect(!model.isRevealed)
    }

    @Test func 앱_상태로_가리기() {
        #expect(PaymentRevealPolicy.shouldMask(on: .background, isRevealed: false))
        #expect(PaymentRevealPolicy.shouldMask(on: .inactive, isRevealed: true))
        #expect(!PaymentRevealPolicy.shouldMask(on: .inactive, isRevealed: false)) // Face ID 창
        #expect(!PaymentRevealPolicy.shouldMask(on: .active, isRevealed: true))
    }
}
