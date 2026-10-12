// UI-IOS-21m · REQ-022 · REQ-095 — 출근 판정 중: 원문 값 · 읽기 문구 · 상태별
import Testing
@testable import Pum

struct CheckInJudgingTests {
    let s = CheckInJudgingState.sample

    @Test func 원문_글자_그대로() {
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(CheckInJudgingState.backTitle == "홈")
        #expect(CheckInJudgingState.title == "출근 확인")
        #expect(CheckInJudgingState.buttonTitle == "확인 중")
        #expect(CheckInJudgingState.footnote == "위치는 지금 한 번만 확인해요")
        #expect(s.steps.map(\.title) == ["QR 확인", "현재 거리 확인 중"])
        #expect(s.steps[0].detail == "종민김밥 본점 \u{00B7} 매장 QR")
        #expect(s.steps[1].detail == "정확도 100m 안이 될 때까지 기다려요")
    }

    @Test func 읽기_문구() {
        #expect(s.steps[0].accessibilityText == "QR 확인, 종민김밥 본점 \u{00B7} 매장 QR, 완료")
        #expect(s.steps[1].accessibilityText == "현재 거리 확인 중, 정확도 100m 안이 될 때까지 기다려요, 확인 중")
    }

    @Test func 행_상태는_서버_값_그대로() {
        #expect(s.steps.map(\.status) == [.done, .checking])
        let done = CheckInJudgingStep(kind: .distance, status: .done)
        #expect(done.statusText == "완료")
        #expect(s.steps[1].statusText == "확인 중")
    }

    @Test func QR만_있어도_행은_목록_그대로() {
        var x = s
        x.steps = [s.steps[0]]
        #expect(x.steps.count == 1)
        #expect(x.steps[0].kind == .qr)
    }
}
