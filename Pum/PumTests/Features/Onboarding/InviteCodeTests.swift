// UI-IOS-2d — 초대 코드: 대문자 영문 + 숫자 6자리 · 매칭 카드 표시 조건 · 문구
import Foundation
import Testing
@testable import Pum

struct InviteCodeTests {
    @Test func 원문_샘플() {
        let s = InviteCodeState.sample
        #expect(s.code == "8F3K2Q")
        #expect(s.isComplete)
        #expect(s.canConfirm)
        #expect(s.visibleMatch?.workplaceName == "종민김밥 본점")
        #expect(s.visibleMatch?.initial == "종")
        #expect(s.visibleMatch?.subtitleText == "박민수 사장님 · 직원 4명 · 초대 유효 6일 남음")
        #expect(s.visibleMatch?.accessibilityText == "종민김밥 본점, 박민수 사장님, 직원 4명, 초대 유효 6일 남음, 확인됨")
    }

    @Test func 대문자_영문_숫자만_여섯자리까지() {
        #expect(InviteCodeState.sanitized("8f3k-2q z9") == "8F3K2Q")
        #expect(InviteCodeState.sanitized("") == "")
        #expect(InviteCodeState.sanitized("가나다") == "")
    }

    @Test func 실제_진입은_빈_코드와_매칭_없음() {
        let s = InviteCodeState.entry
        #expect(s.code.isEmpty)
        #expect(s.matched == nil)
        #expect(!s.canConfirm)
    }

    @Test func 딥링크는_코드가_채워진_채_시작() {
        let s = InviteCodeState.deepLink(code: "8f3k2q")
        #expect(s.code == "8F3K2Q")
        #expect(s.isComplete)
        #expect(s.matched == nil)
        #expect(!s.canConfirm) // 조회 결과가 와야 확인 가능
    }

    @Test func 매칭이_있어도_6자리_미만이면_카드_숨김() {
        var s = InviteCodeState.sample
        s.code = "8F3K2"
        #expect(s.visibleMatch == nil)
        #expect(!s.canConfirm)
    }

    @Test func 사업장_색_번호는_범위_밖이어도_안전() {
        let m = InviteMatch(workplaceName: "가게", ownerName: "김", employeeCount: 1, daysLeft: 1, colorIndex: -3)
        _ = m.tileColor
        #expect(m.initial == "가")
        #expect(InviteMatch(workplaceName: "", ownerName: "", employeeCount: 0, daysLeft: 0, colorIndex: 0).initial == "")
    }

    @Test func 다른_코드로_조회된_결과는_숨김() {
        var s = InviteCodeState(code: "8F3K2P")
        s.matched = InviteCodeState.sample.matched // 8F3K2Q로 조회된 응답이 늦게 옴
        #expect(s.visibleMatch == nil)
        #expect(!s.canConfirm)
        s.code = "8F3K2Q"
        #expect(s.visibleMatch != nil) // 같은 코드를 다시 넣으면 다시 보임
    }

    @Test func 확인은_한_번만_실패하면_다시() {
        var s = InviteCodeState.sample
        let first = s.beginConfirm()
        let second = s.beginConfirm()
        #expect(first)
        #expect(!second)
        s.failConfirm()
        let retry = s.beginConfirm()
        #expect(retry)
    }
}
