// UI-IOS-1al — 퇴근 미확정: 늦게 · 일찍 문구, 시 · 분 조절, 세션 종료 시각, 알림 시각, 사유 없으면 요청 비활성
import Testing
@testable import Pum

struct MissingClockOutTests {
    let s = MissingClockOutState.sample

    @Test func 예정보다_32분_늦게_퇴근() {
        #expect(s.offsetMinutes == 32)
        #expect(s.offsetText == "예정보다 32분 늦게 퇴근")
        #expect(s.recognizedLine == "인정 예상 3시간 04분 \u{00B7} 36,800원")
    }

    @Test func 일찍과_같음_문구() {
        var x = s
        x.inputMinute = 19 * 60 + 15
        #expect(x.offsetText == "예정보다 45분 일찍 퇴근")
        x.inputMinute = 18 * 60 + 30
        #expect(x.offsetText == "예정보다 1시간 30분 일찍 퇴근")
        x.inputMinute = 20 * 60
        #expect(x.offsetText == "예정대로 퇴근")
    }

    @Test func 자정을_넘긴_입력도_이어서_센다() {
        var x = MissingClockOutState.initial
        x.plannedEndMinute = 22 * 60
        x.inputMinute = 30
        #expect(x.offsetMinutes == 150)
    }

    @Test func 기본_진입값은_예정_퇴근_사유_없음() {
        let d = MissingClockOutState.initial
        #expect(d.inputMinute == d.plannedEndMinute)
        #expect(d.selected == nil)
        #expect(d.selectedField == .hour)
        #expect(d.recognizedLine == nil)
    }

    @Test func 시_분_조절_넘김() {
        var x = s
        x.inputMinute = 23 * 60 + 10
        x.step(.hour, by: 1)
        #expect(x.inputMinute == 10)
        x.step(.hour, by: -1)
        #expect(x.inputMinute == 23 * 60 + 10)
        x.inputMinute = 20 * 60 + 59
        x.step(.minute, by: 1)
        #expect(x.inputMinute == 20 * 60)
        x.step(.minute, by: -1)
        #expect(x.inputMinute == 20 * 60 + 59)
        x.step(.hour, by: 1)
        #expect(x.inputText == "21:59")
    }

    @Test func 세션_종료는_예정_퇴근_6시간_뒤() {
        #expect(s.sessionEndText == "새벽 2시")
        var x = s
        x.plannedEndMinute = 23 * 60 + 30
        #expect(x.sessionEndText == "새벽 5시 30분")
        x.plannedEndMinute = 12 * 60
        #expect(x.sessionEndText == "저녁 6시")
    }

    @Test func 알림_시각_문구와_안내() {
        #expect(s.reminderTimesText == "20:00\u{00B7}20:30\u{00B7}21:00")
        #expect(s.noticeLead == "20:00\u{00B7}20:30\u{00B7}21:00 알림에 응답이 없어 새벽 2시에 근무 상태만 종료했어요. ")
        #expect(s.noticeStrong == "20:00 퇴근으로 자동 처리하지 않았고,")
        var x = s
        x.plannedEndMinute = 23 * 60 + 30
        #expect(x.reminderTimesText == "23:30\u{00B7}00:00\u{00B7}00:30")
    }

    @Test func 사유가_없으면_요청_비활성() {
        var x = s
        #expect(x.canRequest)
        x.selected = nil
        #expect(!x.canRequest)
    }

    @Test func 시각을_바꾸면_이전_인정_값은_버린다() {
        var x = MissingClockOutState.sample
        #expect(x.recognizedLine != nil)
        x.step(.minute, by: -1)
        #expect(x.recognizedLine == nil)
    }

    @Test func 휠에서_고른_퇴근_시각_반영() {
        let same = s.applying(pickedMinute: s.inputMinute)
        #expect(same.recognizedText == s.recognizedText)
        let changed = s.applying(pickedMinute: s.inputMinute + 3)
        #expect(changed.inputMinute == s.inputMinute + 3)
        #expect(changed.recognizedText == nil)
        #expect(changed.recognizedPay == nil)
        #expect(s.applying(pickedMinute: 2000).inputMinute == 1439)
    }
}
