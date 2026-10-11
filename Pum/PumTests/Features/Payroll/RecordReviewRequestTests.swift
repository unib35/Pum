// UI-IOS-1ad — 기한 선택 · 버튼 문구 · 현황 문구 · 보내기 중복 방지
import Testing
@testable import Pum

struct RecordReviewRequestTests {
    let s = RecordReviewRequestState.sample

    @Test func 기한_선택에_따른_날짜() {
        var n = s
        #expect(n.choice == .endOfMonth && n.deadlineText == "10월 31일 (금)")
        n.choice = .beforePayday
        #expect(n.deadlineText == "11월 7일 (금)")
        n.choice = .custom
        #expect(n.deadlineText == "" && !n.canSend) // 날짜를 고르기 전엔 보낼 수 없다
        n.customDeadline = "11월 3일 (월)"
        #expect(n.deadlineText == "11월 3일 (월)" && n.canSend)
        #expect(RecordReviewDeadlineChoice.allCases.map(\.title) == ["월말", "급여일 3일 전", "날짜 선택"])
    }

    @Test func 버튼_문구와_0명_비활성() {
        #expect(s.sendTitle == "5명에게 요청 보내기" && s.canSend)
        var n = s
        n.targetCount = 0
        #expect(n.sendTitle == "0명에게 요청 보내기" && !n.canSend)
        n.targetCount = 3
        #expect(n.sendTitle == "3명에게 요청 보내기")
    }

    @Test func 현황_문구() {
        #expect(s.progressText == "3 / 5" && s.replyDeadlineText == "회신 기한 10월 31일")
        #expect(s.targetText == "전체 5명" && s.periodLabel == "10월 1일 \u{2013} 10월 31일")
        #expect(s.people.map(\.chipText) == ["이종민 \u{2713}", "최유나 \u{2713}", "박서준 \u{2713}",
                                              "김하늘 \u{00B7} 수정 요청 1", "정우진 \u{00B7} 미회신"])
        #expect(s.statusAccessibilityLabel == "직원 확인 현황, 5명 중 3명 회신, 김하늘 수정 요청 1건, 정우진 미회신")
        #expect(abs(s.progressFraction - 0.6) < 0.0001)
    }

    @Test func 기본값() {
        #expect(s.choice == .endOfMonth && s.autoSends && !s.isSending)
        #expect(s.message == "11월 10일 급여 확정 전에 한 번 봐주세요. 다른 부분 있으면 수정 요청 남겨주시면 됩니다.")
    }

    @Test func 보내기는_한_번만() {
        var n = s
        let first = n.beginSend()
        #expect(first && n.isSending)
        let second = n.beginSend()
        #expect(!second)
        var z = s
        z.targetCount = 0
        let none = z.beginSend()
        #expect(!none && !z.isSending)
    }

    @Test func 실패하면_다시_보낼_수_있다() {
        var n = s
        let first = n.beginSend()
        let again = n.beginSend()
        #expect(first && !again)
        n.failSend()
        let retry = n.beginSend()
        #expect(retry)
    }
}
