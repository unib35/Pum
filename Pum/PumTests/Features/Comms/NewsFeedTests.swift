// UI-IOS-3a · REQ-041 — 소식: 서버 값 문구 조합 · 필터 · 개수 · 빈 상태
import Testing
@testable import Pum

struct NewsFeedTests {
    let s = NewsFeedState.sample

    @Test func 필터_개수는_안읽은_공지와_요청() {
        #expect(s.unreadNoticeCount == 1)
        #expect(s.requestCount == 2)
        #expect(s.tabBadge == 3)
    }

    @Test func 추가근무_문구는_서버_값_그대로() {
        guard case .extraShift(let r) = s.requests[0] else { Issue.record("추가 근무가 아님"); return }
        #expect(r.detail == "휴일 1.5배 · 예상 126,000원 · 김하늘님에게도 요청됨")
        #expect(r.expectedPay == 126_000)
    }

    @Test func 동시_요청_대상이_없으면_문구에서_빠진다() {
        let r = ExtraShiftRequest(id: "x", ago: "방금", summary: "", multiplierLabel: "평일", expectedPay: 80_000, alsoRequested: nil)
        #expect(r.detail == "평일 · 예상 80,000원")
    }

    @Test func 계약_서명_문구() {
        guard case .contractSign(let r) = s.requests[1] else { Issue.record("계약이 아님"); return }
        #expect(r.detail == "11월 1일부터 11,500 → 12,000원")
    }

    @Test func 필터는_해당_섹션만_보인다() {
        #expect(s.shows(.request, under: .all) && s.shows(.alert, under: .all))
        #expect(s.shows(.notice, under: .notice))
        #expect(!s.shows(.request, under: .notice))
        #expect(!s.shows(.alert, under: .request))
        #expect(NewsFilter.allCases.map(\.title) == ["전체", "공지", "요청", "알림"])
    }

    @Test func 샘플_공지_읽음_상태() {
        #expect(s.notices.map(\.isRead) == [false, true])
        #expect(s.notices[0].linkLabel == "근무 모집 연결됨")
        #expect(s.alerts.map(\.isMuted) == [false, true])
    }

    @Test func 빈_상태() {
        let e = NewsFeedState.empty(workplaceName: "종민김밥 본점", workplaceInitial: "종")
        #expect(e.isEmpty && e.unreadNoticeCount == 0 && !s.isEmpty)
    }
}
