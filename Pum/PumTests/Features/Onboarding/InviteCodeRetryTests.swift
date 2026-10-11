// UI-IOS-15e — 초대 코드 틀림: 오류 문구 · 고치면 지움 · 한 번만 확인
import Foundation
import Testing
@testable import Pum

struct InviteCodeRetryTests {
    @Test func 원문_샘플() {
        let s = InviteCodeRetryState.sample
        #expect(s.code == "8F3K2P")
        #expect(s.isError)
        #expect(s.errorText == "코드가 맞지 않아요 · 4번 더 입력할 수 있어요")
        #expect(s.canConfirm)
    }

    @Test func 코드를_고치면_오류를_지운다() {
        var s = InviteCodeRetryState.sample
        s.codeChanged(to: "8F3K2")
        #expect(!s.isError)
        #expect(s.errorText == nil)
        #expect(!s.canConfirm)
    }

    @Test func 같은_코드면_오류_유지() {
        var s = InviteCodeRetryState.sample
        s.codeChanged(to: "8F3K2P")
        #expect(s.isError)
    }

    @Test func 남은_횟수_0이면_확인_비활성() {
        let s = InviteCodeRetryState(code: "8F3K2P", remainingAttempts: 0, isError: true)
        #expect(s.isLocked)
        #expect(!s.canConfirm)
        #expect(s.errorText == "코드가 맞지 않아요")
    }

    @Test func 횟수를_모르면_횟수_없는_문구() {
        let s = InviteCodeRetryState(code: "8F3K2P", remainingAttempts: nil, isError: true)
        #expect(s.errorText == "코드가 맞지 않아요")
    }

    @Test func 확인은_한_번만_실패하면_풀린다() {
        var s = InviteCodeRetryState.sample
        let first = s.beginConfirm()
        let second = s.beginConfirm()
        #expect(first)
        #expect(!second)
        s.failConfirm()
        #expect(s.canConfirm)
    }

    @Test func 여섯자리_미만은_확인_불가() {
        #expect(!InviteCodeRetryState(code: "8F3").canConfirm)
        #expect(InviteCodeRetryState(code: "8f3k-2p9").code == "8F3K2P")
    }
}
