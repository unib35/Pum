// UI-IOS-10t · REQ-022 — 출근 판정 통과: 서버 값 그대로 표시
import Testing
@testable import Pum

struct CheckInPassedTests {
    let s = CheckInPassedState.sample

    @Test func 원문_글자_그대로() {
        #expect(s.subtitle == "종민김밥 본점 \u{00B7} 10월 6일 화")
        #expect(s.clockInText == "09:57")
        #expect(s.plannedLine == "예정 10:00 \u{2013} 15:00 \u{00B7} 3분 일찍")
        #expect(s.clockOutNotice == "예정 퇴근 15:00에 알려드려요")
        #expect(s.clockOutHow == "같은 QR을 다시 스캔")
    }

    @Test func 확인_행은_서버_목록_그대로() {
        #expect(s.checks.map(\.title) == ["QR 확인", "위치 확인"])
        #expect(s.checks[0].detail == "종민김밥 본점 출근 QR")
        #expect(s.checks[1].detail == "사업장에서 18m \u{00B7} 허용 100m")
        #expect(s.checks[0].accessibilityText == "QR 확인, 종민김밥 본점 출근 QR, 완료")
    }

    @Test func 위치만_방식은_QR_행이_없다() {
        var x = s
        x.checks = [s.checks[1]]
        #expect(x.checks.count == 1)
        #expect(x.checks[0].kind == .location)
    }

    @Test func 판정_문구가_없으면_예정만() {
        var x = s
        x.timingNote = nil
        #expect(x.plannedLine == "예정 10:00 \u{2013} 15:00")
    }

    @Test func 큰_시각_음성_문구() {
        #expect(s.clockInAccessibility == "출근 시각 9시 57분")
    }
}
