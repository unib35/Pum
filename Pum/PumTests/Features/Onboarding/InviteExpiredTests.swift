// UI-IOS-15f — 초대 만료: 문구 조합 · 만료 읽기 · 한 번만 요청 잠금
import Testing
@testable import Pum

struct InviteExpiredTests {
    let s = InviteExpiredState.sample

    @Test func 원문_문구_조합() {
        #expect(s.expiredLine == "10월 14일에 만료됐어요 · 이 초대로는 수락할 수 없어요")
        #expect(s.subtitleText == "서울 마포구 양화로 12 · 음식점")
        #expect(s.requestTitle == "박민수 사장님에게 다시 요청")
        #expect(s.requestNote == "사장님 앱에 \"한지우님이 새 초대를 요청했어요\" 알림이 가요")
        #expect(s.initial == "종")
    }

    @Test func 만료_행은_색만으로_알리지_않는다() {
        #expect(s.expiryValue == "10월 14일 만료")
        #expect(s.expiryAccessibilityText == "초대 유효, 10월 14일 만료")
    }

    @Test func 사업장_색_번호_방어() {
        var x = s
        for i in [0, -1, -7, 5, 100] { x.colorIndex = i; _ = x.tileColor }
        #expect(x.initial == "종")
    }

    @Test func 다시_요청은_한_번만() {
        var lock = InviteRequestLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        #expect(lock.isSending)
    }

    @Test func 실패하면_다시_누를_수_있다() {
        var lock = InviteRequestLock()
        _ = lock.begin()
        lock.finish(success: false)
        #expect(!lock.isSending)
        let again = lock.begin()
        #expect(again)
    }

    @Test func 성공하면_잠근_채_둔다() {
        var lock = InviteRequestLock()
        _ = lock.begin()
        lock.finish(success: true)
        #expect(lock.isSending)
    }
}
