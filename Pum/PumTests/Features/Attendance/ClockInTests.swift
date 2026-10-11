// UI-IOS-1e — 출근 기록: 위치 판정 · 정시 안내 조건 · 문구
import Testing
@testable import Pum

struct ClockInTests {
    let s = ClockInState.sample

    @Test func 거리가_반경_이하면_확인됨() {
        #expect(s.locationStatus == .confirmed)
        var x = s
        x.distanceMeters = 100
        #expect(x.locationStatus == .confirmed) // 경계 포함
    }

    @Test func 거리가_반경_초과면_거리_초과() {
        var x = s
        x.distanceMeters = 101
        #expect(x.locationStatus == .outOfRange)
    }

    @Test func 정확도가_100m_초과면_판정_보류() {
        var x = s
        x.accuracyMeters = 101
        #expect(x.locationStatus == .undetermined)
        x.accuracyMeters = 100
        #expect(x.locationStatus == .confirmed)
    }

    @Test func 확인_중이면_확인_중() {
        var x = s
        x.isChecking = true
        #expect(x.locationStatus == .checking)
    }

    @Test func 정시_출근_문구는_예정_플러스마이너스_45분_안일_때만() {
        #expect(s.onTimeNote == "정시 출근으로 기록돼요")
        var x = s
        x.now = x.plannedStart + 45
        #expect(x.onTimeNote != nil)
        x.now = x.plannedStart - 45
        #expect(x.onTimeNote != nil)
        x.now = x.plannedStart + 46
        #expect(x.onTimeNote == nil)
        x.now = x.plannedStart - 46
        #expect(x.onTimeNote == nil)
    }

    @Test func 확인_중이_다른_판정보다_먼저() {
        var x = s
        x.isChecking = true
        x.accuracyMeters = 101
        x.distanceMeters = 500
        #expect(x.locationStatus == .checking)
    }

    @Test func 정확도_초과는_거리_초과보다_먼저() {
        var x = s
        x.accuracyMeters = 101
        x.distanceMeters = 500
        #expect(x.locationStatus == .undetermined)
        x.accuracyMeters = 100
        #expect(x.locationStatus == .outOfRange)
    }

    @Test func 위치가_확인되지_않으면_정시_안내_없음() {
        var x = s
        x.distanceMeters = 101
        #expect(x.onTimeNote == nil)
        x = s
        x.accuracyMeters = 101
        #expect(x.onTimeNote == nil)
        x = s
        x.isChecking = true
        #expect(x.onTimeNote == nil)
    }

    @Test func 위치_카드_음성_문장() {
        #expect(s.locationAccessibilityText == "현재 위치 확인됨. 종민김밥 본점에서 32m, 허용 반경 100m")
    }

    // 원문 = 디자인 1e 화면 글자(screen-index 72행은 줄인 요약)
    @Test func 문구는_원문_그대로() {
        #expect(s.locationDetail == "종민김밥 본점에서 32m \u{00B7} 허용 반경 100m")
        #expect(s.scanHint == "계산대 옆 QR \u{00B7} 종민김밥 본점")
        #expect(s.plannedText == "예정 출근 17:00")
    }
}
