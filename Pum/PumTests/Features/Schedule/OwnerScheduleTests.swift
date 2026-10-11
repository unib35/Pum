// UI-IOS-1t — 사업장 스케줄: 주간 7칸 · 선택, 부족 · 휴무, 시간대 그룹, 대타 카드 문구
import Testing
@testable import Pum

struct OwnerScheduleTests {
    let s = OwnerScheduleState.sample

    @Test func 주간_7칸과_선택_바꾸기() {
        #expect(s.days.count == 7)
        #expect(s.days.map(\.weekday) == ["월", "화", "수", "목", "금", "토", "일"])
        #expect(s.weekTitle == "10월 5일 \u{2013} 11일")
        var t = s
        #expect(t.selectedDay?.id == 5)
        t.select(9)
        #expect(t.selectedDay?.title == "10월 9일 금 \u{00B7} 4명 \u{00B7} 21시간")
        t.select(99) // 없는 날은 무시
        #expect(t.selectedID == 9)
    }

    @Test func 부족_휴무_표시와_음성() {
        #expect(s.days[3].isShort && s.days[3].countText == "1명")
        #expect(s.days.filter(\.isShort).count == 1)
        #expect(s.days[6].isClosed && s.days[6].isSunday && s.days[6].countText == "휴무")
        #expect(s.days[0].accessibilityLabel(selected: true) == "10월 5일 월요일, 4명, 선택됨")
        #expect(s.days[3].accessibilityLabel(selected: false) == "10월 8일 목요일, 1명, 인원 부족")
        #expect(s.days[6].accessibilityLabel(selected: false) == "10월 11일 일요일, 휴무")
    }

    @Test func 시간대_그룹_문구() {
        let g = s.days[0].groups
        #expect(s.days[0].title == "10월 5일 월 \u{00B7} 4명 \u{00B7} 22시간")
        #expect(g.count == 2)
        #expect(g[0].start == "09:00" && g[0].end == "15:00" && g[0].periodText == "오전 \u{00B7} 6h")
        #expect(g[1].start == "17:00" && g[1].end == "22:00" && g[1].periodText == "오후 \u{00B7} 5h")
        #expect(g[0].people.map(\.name) == ["최유나", "박서준"])
        #expect(g[1].people.map(\.name) == ["이종민", "김하늘"])
        #expect(g[0].people[0].breakLabel == "휴게 1h" && g[1].people[1].breakLabel == "휴게 30m")
    }

    @Test func 대타_카드_문구() throws {
        let w = try #require(s.swap)
        #expect(w.title == "대타 요청 1건")
        #expect(w.requestedAgo == "어제 21:40")
        #expect(w.whenText == "10월 12일 월 \u{00B7} 17:00 \u{2013} 22:00")
        #expect(w.weekHoursText == "그 주 박서준 23h \u{2192} 28h")
        #expect(w.accessibilityText == "대타 요청, 10월 12일 월요일 17:00부터 22:00, 이종민에서 박서준으로, 그 주 박서준 23시간에서 28시간")
    }
}
