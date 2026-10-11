// UI-IOS-1ar — 사장님 홈(할 일 0건) 개수 · 비율 · 문구
import Foundation
import Testing
@testable import Pum

struct OwnerHomeClearTests {
    let s = OwnerHomeClearState.sample

    @Test func 오늘_근무_4명_지금_2명() {
        #expect(s.todayCount == 4)
        #expect(s.todayTitle == "오늘 근무 4명")
        #expect(s.working.count == 2)
        #expect(s.nowSummary == "지금 2명 · 13:20")
    }

    @Test func 근무_중_진행_비율은_0에서_1() {
        for p in s.working {
            let r = p.progress(now: s.nowMinute)
            #expect(r > 0 && r < 1)
        }
        #expect(abs(s.working[0].progress(now: s.nowMinute) - 265.0 / 365.0) < 0.0001)
        #expect(s.working[0].progress(now: 0) == 0)
        #expect(s.working[0].progress(now: 23 * 60) == 1)
        #expect(s.working[0].detail == "08:55 출근 · 15:00 퇴근 예정")
        #expect(s.working[1].detail == "09:03 출근 · 15:00 퇴근 예정")
    }

    @Test func 예정_행은_막대_없이_시간_문구만() {
        #expect(s.scheduled.map(\.detail) == ["17:00 – 22:00 예정", "17:00 – 22:00 예정"])
        #expect(s.scheduled.map(\.name) == ["이종민", "김하늘"])
    }

    @Test func 남은_예정은_예상에서_확정을_뺀_값() {
        #expect(s.remainingPay == s.expectedPay - s.confirmedPay)
        #expect(s.remainingPay == 1_530_000)
        #expect(abs(s.confirmedRatio - 2_680_000.0 / 4_210_000.0) < 0.0001)
        #expect(OwnerHomeFormat.won(s.expectedPay) == "4,210,000원")
    }
}
