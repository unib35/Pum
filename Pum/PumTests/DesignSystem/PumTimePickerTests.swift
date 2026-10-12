// 공통 PumTimePicker — 휠 값 목록 · 스냅 · 문구 · 표시용 길이 (C13)
import Testing
@testable import Pum

struct PumTimePickerTests {
    @Test func 값목록_30분_간격은_48개_0시부터_23시30분까지() {
        let v = PumTimeWheelMath.values(interval: 30)
        #expect(v.count == 48)
        #expect(v.first == 0)
        #expect(v.last == 23 * 60 + 30)
    }

    @Test func 값목록_간격이_달라지고_0이하는_1분() {
        #expect(PumTimeWheelMath.values(interval: 60).count == 24)
        #expect(PumTimeWheelMath.values(interval: 15).count == 96)
        #expect(PumTimeWheelMath.values(interval: 0).count == 1440)
    }

    @Test func 스냅_가장_가까운_값_하루_경계() {
        #expect(PumTimeWheelMath.snapped(1020, interval: 30) == 1020)
        #expect(PumTimeWheelMath.snapped(1034, interval: 30) == 1020)
        #expect(PumTimeWheelMath.snapped(1035, interval: 30) == 1050)
        #expect(PumTimeWheelMath.snapped(-40, interval: 30) == 0)
        #expect(PumTimeWheelMath.snapped(1439, interval: 30) == 1410) // 24:00은 없다
        #expect(PumTimeWheelMath.snapped(5000, interval: 30) == 1410)
    }

    @Test func 한칸씩_이동은_끝에서_멈춘다() {
        #expect(PumTimeWheelMath.stepped(1020, by: 1, interval: 30) == 1050)
        #expect(PumTimeWheelMath.stepped(1020, by: -2, interval: 30) == 960)
        #expect(PumTimeWheelMath.stepped(0, by: -1, interval: 30) == 0)
        #expect(PumTimeWheelMath.stepped(1410, by: 1, interval: 30) == 1410)
    }

    @Test func 시각_문구() {
        #expect(PumTimeWheelMath.clockText(0) == "00:00")
        #expect(PumTimeWheelMath.clockText(1020) == "17:00")
        #expect(PumTimeWheelMath.clockText(1410) == "23:30")
    }

    @Test func 음성_문구() {
        #expect(PumTimeWheelMath.spokenText(1020) == "오후 5시")
        #expect(PumTimeWheelMath.spokenText(1050) == "오후 5시 30분")
        #expect(PumTimeWheelMath.spokenText(0) == "오전 12시")
        #expect(PumTimeWheelMath.spokenText(720) == "오후 12시")
        #expect(PumTimeWheelMath.spokenText(570) == "오전 9시 30분")
    }

    @Test func 길이_요약_원문_예시() {
        #expect(PumTimeWheelMath.summary(start: 1020, end: 1320) == "17:00 → 22:00 · 5시간")
    }

    @Test func 길이_분이_있으면_함께() {
        #expect(PumTimeWheelMath.summary(start: 540, end: 870) == "09:00 → 14:30 · 5시간 30분")
        #expect(PumTimeWheelMath.durationText(minutes: 30) == "30분")
    }

    @Test func 다음날로_넘어가면_24시간을_더한다() {
        // 22:00 → 06:00 = 8시간
        #expect(PumTimeWheelMath.displayMinutes(start: 1320, end: 360) == 480)
        #expect(PumTimeWheelMath.summary(start: 1320, end: 360) == "22:00 → 06:00 · 8시간")
        #expect(PumTimeWheelMath.displayMinutes(start: 600, end: 600) == 0)
    }

    @Test func 기본값은_원문_상태() {
        let v = PumTimeRangeValue()
        #expect(PumTimeWheelMath.summary(start: v.startMinutes, end: v.endMinutes) == "17:00 → 22:00 · 5시간")
        #expect(v.breakMinutes == 30)
        #expect(v.weekdays == [1, 3, 5])
        #expect(v.endDateText == "없음")
    }
}
