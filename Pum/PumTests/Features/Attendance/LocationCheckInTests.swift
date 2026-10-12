// UI-IOS-10v · REQ-022 · REQ-023 — 위치만 간편 출근: 서버 값 표시 · 단위 · 잠금
import Testing
@testable import Pum

struct LocationCheckInTests {
    let s = LocationCheckInState.sample

    @Test func 원문_글자() {
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.shiftText == "17:00 \u{2013} 22:00")
        #expect(s.distanceDetail == "종민김밥 \u{00B7} 12m")
        #expect(s.radiusText == "허용 100m")
        #expect(s.methodDetail == "사업장 설정 \u{00B7} 사장님이 정해요")
    }

    @Test func 거리_단위는_10u와_같다() {
        #expect(LocationCheckInState.lengthText(999) == "999m")
        #expect(LocationCheckInState.lengthText(2450) == "2.5km")
    }

    @Test func 읽기_문장() {
        #expect(s.locationAccessibilityLabel == "현재 위치, 종민김밥, 12미터, 허용 100미터, 확인됨")
    }

    @Test func 판정_값이_없어도_문장이_만들어진다() {
        var n = s
        n.distanceMeters = nil
        #expect(n.distanceDetail == nil)
        #expect(n.locationAccessibilityLabel == "현재 위치, 아직 확인 전, 허용 100미터")
    }

    @Test func 출근하기는_한_번만_끝나면_풀림() {
        var lock = LocationCheckInLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish()
        #expect(!lock.isChecking)
        let third = lock.begin()
        #expect(third)
    }
}
