// UI-IOS-10u · REQ-022 — 출근 판정 · 거리 초과: 서버 값 표시 · 단위 · 잠금
import Testing
@testable import Pum

struct CheckInTooFarTests {
    let s = CheckInTooFarState.sample

    @Test func 원문_글자() {
        #expect(s.subtitle == "종민김밥 본점 \u{00B7} 10월 6일 화 09:56")
        #expect(s.qrDetail == "종민김밥 본점 출근 QR")
        #expect(s.locationDetail == "현재 거리 2.4km \u{00B7} 허용 100m")
        #expect(s.accuracyText == "\u{00B1}12m")
        #expect(s.ownerRowDetail == "승인되면 09:56 출근으로 기록")
    }

    @Test func 거리_단위() {
        #expect(CheckInTooFarState.lengthText(999) == "999m")
        #expect(CheckInTooFarState.lengthText(1000) == "1km")
        #expect(CheckInTooFarState.lengthText(2400) == "2.4km")
        #expect(CheckInTooFarState.lengthText(2449) == "2.4km")
        #expect(CheckInTooFarState.lengthText(2450) == "2.5km")
        #expect(CheckInTooFarState.lengthText(0) == "0m")
    }

    @Test func 읽기_문장() {
        #expect(s.locationAccessibilityLabel == "위치 확인, 실패, 현재 거리 2.4킬로미터, 허용 100미터")
        #expect(s.accuracyAccessibilityLabel == "위치 정확도, 측정은 정확해요, 플러스마이너스 12미터")
        #expect(s.ownerRowAccessibilityLabel == "매장에 있는데 안 된다면, 승인되면 09:56 출근으로 기록, 사장님에게 확인 요청")
    }

    @Test func 다시_확인은_한_번만_끝나면_풀림() {
        var lock = CheckInTooFarLock()
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
