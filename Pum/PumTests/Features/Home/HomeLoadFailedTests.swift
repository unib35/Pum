// UI-IOS-21n · REQ-095 · M38 — 사장님 홈 불러오기 실패 기본값 · 원문 문구
import Testing
@testable import Pum

struct HomeLoadFailedTests {
    @Test func 기본값은_실패_아님() {
        #expect(OwnerHomeView().staleSince == nil)
        #expect(OwnerHomeView(isLoading: true).staleSince == nil)
    }

    @Test func 실패_상태_예시() {
        #expect(OwnerHomeView(staleSince: OwnerHomeLoadFailed.sampleSince).staleSince == "15:12")
    }

    @Test func 원문_문구() {
        let since = OwnerHomeLoadFailed.sampleSince
        #expect(since == "15:12")
        #expect(OwnerHomeLoadFailed.sinceLine(since) == "15:12 기준")
        #expect(OwnerHomeLoadFailed.title == "새 정보를 불러오지 못했어요")
        #expect(OwnerHomeLoadFailed.reason(since: since) == "15:12에 받은 화면이에요 · 출퇴근 기록은 그대로 저장돼요")
        #expect(OwnerHomeLoadFailed.retryTitle == "다시 시도")
        #expect(OwnerHomeLoadFailed.staleOpacity == 0.6)
    }
}
