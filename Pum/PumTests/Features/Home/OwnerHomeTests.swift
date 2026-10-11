// UI-IOS-1aq — 사장님 홈 개수 · 비율 · 문구
import Foundation
import Testing
@testable import Pum

struct OwnerHomeTests {
    let s = OwnerHomeState.sample

    @Test func 처리할_일_6은_행_2와_그_밖에_4() {
        #expect(s.decisions.count == 2)
        #expect(s.otherCount == 4)
        #expect(s.attentionCount == 6)
    }

    @Test func 인건비_확정_비율과_남은_예정() {
        #expect(s.expectedPay == 4_210_000)
        #expect(s.remainingPay == s.expectedPay - s.confirmedPay)
        #expect(s.remainingPay == 1_530_000)
        #expect(abs(s.confirmedRatio - 2_680_000.0 / 4_210_000.0) < 0.0001)
        #expect(OwnerHomeFormat.won(s.confirmedPay) == "2,680,000원")
    }

    @Test func 문구_지남과_연장() {
        let yuna = s.working[0]
        #expect(yuna.overdueMinutes(now: s.nowMinute) == 40)
        #expect(OwnerHomeFormat.overdue(minutes: 40) == "40분 지남")
        #expect(OwnerHomeFormat.overdue(minutes: 65) == "1시간 5분 지남")
        #expect(OwnerHomeFormat.overtime(minutes: 62) == "연장 1시간 2분")
        #expect(s.decisions[0].title == "김하늘 · 연장 1시간 2분")
        #expect(s.decisions[1].title == "박서준 · 퇴근 기록 없음")
        #expect(yuna.detail(now: s.nowMinute) == "08:55 출근 · 예정 15:00")
        #expect(s.working[1].detail(now: s.nowMinute) == "14:57 출근 · 22:00 퇴근 예정")
    }

    @Test func 진행_비율은_0에서_1() {
        let p = s.working[1]
        #expect(p.isOverdue(now: s.nowMinute) == false)
        #expect(abs(p.progress(now: s.nowMinute) - 43.0 / 423.0) < 0.0001)
        #expect(p.progress(now: 0) == 0)
        #expect(p.progress(now: 23 * 60) == 1)
    }

    @Test func 경계값() {
        let s = OwnerHomeState.sample
        // 예정 퇴근과 같은 분이면 지남이 아님
        if let d = s.working.first {
            #expect(d.isOverdue(now: d.plannedEndMinute) == false)
            #expect(d.overdueMinutes(now: d.plannedEndMinute + 40) == 40)
        }
        #expect(s.decisions.map(\.actionTitle) == ["인정", "처리"])
        #expect(s.remainingPay == s.expectedPay - s.confirmedPay)
        #expect(s.confirmedRatio >= 0 && s.confirmedRatio <= 1)
    }
}
