// UI-IOS-17a · UI-IOS-17b — 다음 주 초안 · 근무 추가 시트: 원문 값 · 읽기 문구 · 시트 초안 기본값 · 서버 계산 글자
import Testing
@testable import Pum

struct ScheduleDraftTests {
    let s = ScheduleDraftState.sample

    @Test func 주간_7칸과_원문_글자() {
        #expect(s.days.count == 7)
        #expect(s.days.map(\.weekday) == ["월", "화", "수", "목", "금", "토", "일"])
        #expect(s.days.map(\.countText) == ["4명", "2명", "3명", "3명", "4명", "5명", "2명"])
        #expect(s.days.filter(\.isRed).map(\.weekday) == ["금", "일"])
        #expect(s.weekTitle == "10월 5일 \u{2013} 11일")
        #expect(ScheduleDraftState.draftBadge == "초안 \u{00B7} 직원에게 안 보임")
        #expect(s.selectedID == 7 && s.selectedDay?.weekday == "수")
        #expect(s.selectedTitle == "10월 7일 수 \u{00B7} 3명")
        #expect(s.footnote == "바뀐 것 3건 \u{00B7} 게시하면 직원 6명에게 알림")
        #expect(s.workTabBadge == 4)
        #expect(s.sheet == nil)
    }

    @Test func 날짜_선택은_화면_상태만_바꾼다() {
        var t = s
        t.select(9)
        #expect(t.selectedID == 9)
        t.select(99) // 없는 날은 무시
        #expect(t.selectedID == 9)
    }

    @Test func 근무_세_줄과_배지() {
        #expect(s.shifts.map(\.name) == ["최유나", "김하늘", "이종민"])
        #expect(s.shifts.map(\.badgeText) == ["변경", nil, "추가"])
        #expect(s.shifts[0].note == "출근 09:00 \u{2192} 10:00 \u{00B7} 휴게 30분")
        #expect(s.shifts[1].start == "17:00" && s.shifts[1].end == "22:00")
    }

    @Test func 읽기_문구() {
        #expect(s.shifts[0].accessibilityText == "10:00부터 15:00, 최유나, 출근 09:00 \u{2192} 10:00 \u{00B7} 휴게 30분, 변경")
        #expect(s.shifts[1].accessibilityText == "17:00부터 22:00, 김하늘, 휴게 30분")
        #expect(s.shifts[2].accessibilityText == "17:00부터 22:00, 이종민, 휴게 30분, 추가")
        #expect(s.days[2].accessibilityLabel() == "10월 7일 수요일, 3명")
    }

    @Test func 시트는_열린_상태에서_시작() {
        #expect(ScheduleDraftState.addingShift.sheet == AddShiftSheetState.sample)
        #expect(ScheduleDraftState.addingShift.shifts == s.shifts)
    }

    @Test func 시트_원문_글자와_초안_기본값() {
        let sheet = AddShiftSheetState.sample
        #expect(sheet.title == "근무 추가 \u{00B7} 10월 7일 수")
        #expect(sheet.badge == "초안")
        #expect(sheet.staff.map(\.name) == ["박서준", "오세진", "정다은", "김하늘"])
        #expect(sheet.repeatOptions == ["이번만", "매주 수"])
        #expect(AddShiftSheetState.addTitle == "초안에 추가")
        let d = sheet.initialDraft
        #expect(d.staffID == 1 && d.repeatIndex == 0 && d.breakMinutes == 30)
        #expect(sheet.clock(d.startMinutes) == "17:00" && sheet.clock(d.endMinutes) == "22:00")
        #expect(sheet.breakText(30) == "30분" && sheet.breakText(60) == "1시간" && sheet.breakText(0) == "없음")
        #expect(sheet.focusedField == .start)
        #expect(!sheet.hasChanges(d))
    }

    @Test func 초안_바꾸면_변경으로_본다() {
        let sheet = AddShiftSheetState.sample
        var d = sheet.initialDraft
        d.staffID = 2
        #expect(sheet.hasChanges(d))
    }

    @Test func 계산_값은_서버_글자_그대로() {
        let e = AddShiftSheetState.sample.estimate
        #expect(e.title == "박서준 \u{00B7} 이 주 근무")
        #expect(e.hoursText == "23h \u{2192} 27h 30m")
        #expect(e.costLabel == "예상 인건비")
        #expect(e.basis == "기본 49,500 \u{00B7} 소정근로 25h 초과 2.5h 가산 13,750")
        #expect(e.total == "+63,250원")
        #expect(e.accessibilityText == "박서준 \u{00B7} 이 주 근무, 23h \u{2192} 27h 30m, 예상 인건비 +63,250원, 기본 49,500 \u{00B7} 소정근로 25h 초과 2.5h 가산 13,750")
    }
}
