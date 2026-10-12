// UI-IOS-10w · REQ-022 · REQ-029 — 위치 오차가 클 때: 서버 값 표시 · 대체 경로 · 잠금
import Testing
@testable import Pum

struct CheckInLowAccuracyTests {
    let s = CheckInLowAccuracyState.sample

    @Test func 원문_글자() {
        #expect(s.subtitle == "종민김밥 본점 \u{00B7} 10월 6일 화 16:57")
        #expect(s.locationDetail == "오차 \u{00B1}180m \u{00B7} 허용 100m보다 커요")
        #expect(s.hint == "실내나 지하에서는 오차가 커질 수 있어요")
        #expect(s.alternatives.map(\.title) == ["매장 QR로 확인", "사장님에게 확인 요청"])
        #expect(s.alternatives.map(\.detail) == ["카운터 옆 출근 QR", "승인되면 16:57 출근"])
    }

    @Test func 읽기_문장() {
        #expect(s.locationAccessibilityLabel == "위치 확인, 보류, 오차 180미터, 허용 100미터보다 커요")
        #expect(s.accessibilityLabel(for: s.alternatives[0]) == "매장 QR로 확인, 카운터 옆 출근 QR")
    }

    @Test func QR_없는_매장은_대체_경로가_하나() {
        var t = s
        t.alternatives = s.alternatives.filter { $0.kind == .requestOwner }
        #expect(t.alternatives.count == 1)
    }

    @Test func 다시_시도는_한_번만_끝나면_풀림() {
        var lock = CheckInLowAccuracyLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        #expect(lock.isChecking)
        lock.finish()
        #expect(!lock.isChecking)
        let third = lock.begin()
        #expect(third)
    }
}
