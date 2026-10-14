// UI-IOS-21d · REQ-076 · DEC-003 — 입금 확인 요청: 서버 값 그대로 · 한 번만 · 처리 중 닫기 막기
import Testing
import Foundation
@testable import Pum

struct PaymentCheckRequestTests {
    let s = PaymentCheckRequestState.sample

    @Test func 원문_값() {
        #expect(s.headline == "김하늘 \u{00B7} 아직 들어오지 않았어요")
        #expect(s.requestSubtitle == "11월 11일 11:05 \u{00B7} \u{300C}국민은행 앱에서 확인했어요\u{300D}")
        #expect(s.amountLabel == "10월분 실지급액")
        #expect(s.amountText == "1,062,000원")
        #expect(s.sentAccount == "국민은행 123456-78-901234")
        #expect(s.paidSubtitle == "11월 10일 14:20 \u{00B7} 박민수")
        #expect(s.revertTitle == "지급 대기로" && s.confirmTitle == "보낸 게 맞아요")
    }

    @Test func 안내는_서버_이름으로_조립() {
        #expect(s.notice == "\u{300C}보낸 게 맞아요\u{300D}를 누르면 김하늘님에게 다시 확인했다고 알려요")
        var x = s
        x.employeeName = "최유나"
        #expect(x.notice.contains("최유나님에게"))
    }

    @Test func 금액은_정수_원() {
        var x = s
        x.netPay = 880_000
        #expect(x.amountText == "880,000원")
    }

    @Test func 계좌는_뒤_4자리만_보인다() { // DEC-017
        #expect(s.displayAccount == "국민은행 \u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}-\u{2022}\u{2022}-\u{2022}\u{2022}1234")
        var x = s
        x.sentAccount = "국민은행 \u{2022}\u{2022}\u{2022}\u{2022}1234" // 서버가 가려 보내도 그대로
        #expect(x.displayAccount == "국민은행 \u{2022}\u{2022}\u{2022}\u{2022}1234")
    }

    @Test func 시각_표기와_읽기() {
        #expect(s.requestedAt.text == "11월 11일 11:05")
        #expect(s.requestedAt.spoken == "11월 11일 11시 5분")
    }

    @Test func 머리_읽기() {
        #expect(s.headSpoken == "김하늘, 아직 들어오지 않았어요, 11월 11일 11시 5분, 메모 국민은행 앱에서 확인했어요")
    }

    @Test func 계좌는_숫자를_하나씩_읽는다() {
        #expect(PaymentCheckRequestState.digitsSpoken("국민은행 12-3") == "국민은행 1 2, 3")
        #expect(s.accountSpoken.hasPrefix("보낸 계좌, 국민은행 가림"))
        #expect(s.accountSpoken.hasSuffix("1 2 3 4"))
        #expect(PaymentCheckRequestState.digitsSpoken("국민 \u{2022}\u{2022}12").contains("가림"))
    }

    @Test func 한_번만_누르면_잠기고_두_번째는_거절() {
        var lock = PaymentCheckConfirmLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        #expect(lock.isConfirming)
    }

    @Test func 실패면_풀리고_성공이면_잠김_유지() {
        var lock = PaymentCheckConfirmLock()
        _ = lock.begin()
        lock.finish(success: false)
        #expect(!lock.isConfirming)
        _ = lock.begin()
        lock.finish(success: true)
        #expect(lock.isConfirming)
    }

    @Test func 처리_중에는_시트_닫기를_막는다() {
        #expect(!PaymentCheckRequestState.allowsSheetChange(to: false, isConfirming: true))
        #expect(PaymentCheckRequestState.allowsSheetChange(to: false, isConfirming: false))
        #expect(PaymentCheckRequestState.allowsSheetChange(to: true, isConfirming: true))
    }
}
