// UI-IOS-1j · REQ-042 — 내 스케줄: 행 문구 · 배지 · 섹션 · 대타 요청 시트 문구
import Testing
@testable import Pum

struct MyScheduleTests {
    let s = MyScheduleState.sample
    var all: [ScheduleItem] { s.sections.flatMap(\.items) }
    func item(_ day: Int) -> ScheduleItem { all.first { $0.day == day }! }

    @Test func 시간_문구는_en_dash() {
        #expect(item(5).timeRange == "17:00 \u{2013} 22:00")
        #expect(item(9).timeRange == "18:00 \u{2013} 23:00")
    }

    @Test func 섹션은_이번_주_다음_주_순서() {
        #expect(s.sections.map(\.title) == ["이번 주 · 10월 첫째 주", "다음 주"])
        #expect(s.sections[0].items.map(\.day) == [3, 5, 7, 9])
        #expect(s.sections[1].items.map(\.day) == [12, 14])
    }

    @Test func 오늘_행은_출근_전_배지_꺾쇠_없음() {
        let t = item(3)
        #expect(t.isToday)
        #expect(t.badge?.text == "출근 전")
        #expect(t.badge?.kind == .waiting)
        #expect(!t.showsChevron)
        #expect(t.subtitle == "종민김밥 본점 · 휴게 30분")
    }

    @Test func 일반_행은_꺾쇠_배지_없음() {
        let n = item(5)
        #expect(n.badge == nil)
        #expect(n.showsChevron)
        #expect(n.subtitle == "종민김밥 본점")
        #expect(!n.isToday && !n.isChanged && !n.isSubstituteRequested)
    }

    @Test func 변경됨_행은_기존_시간을_보여_준다() {
        let c = item(9)
        #expect(c.isChanged)
        #expect(c.subtitle == "종민김밥 본점 · 기존 17:00 \u{2013} 22:00")
        #expect(c.showsChevron)
        #expect(ScheduleItem.changedText == "변경됨")
    }

    @Test func 대타_요청_중_행은_경고_배지_강조() {
        let r = item(12)
        #expect(r.isSubstituteRequested)
        #expect(r.badge?.text == "대타 요청 중")
        #expect(r.badge?.kind == .attention)
        #expect(!r.showsChevron)
        #expect(r.timeRange == "17:00 \u{2013} 22:00") // 승인 전까지 예정대로(REQ-042)
        #expect(all.filter(\.isSubstituteRequested).count == 1)
    }

    @Test func 행_음성_문구() {
        #expect(item(9).accessibilityLabel == "10월 9일 금요일, 18:00부터 23:00, 변경됨, 기존 17:00부터 22:00")
        #expect(item(5).accessibilityLabel == "10월 5일 월요일, 17:00부터 22:00, 종민김밥 본점")
        #expect(item(3).accessibilityLabel == "오늘, 10월 3일 토요일, 17:00부터 22:00, 출근 전, 종민김밥 본점, 휴게 30분")
        #expect(item(12).accessibilityLabel == "10월 12일 월요일, 17:00부터 22:00, 대타 요청 중, 종민김밥 본점")
    }

    @Test func 시트_문구() throws {
        let r = try #require(s.substitute)
        #expect(r.title == "10월 12일 월 \u{00B7} 17:00 \u{2013} 22:00")
        #expect(r.statusText == "승인 대기")
        #expect(r.applicantsHeader == "신청한 직원 1명")
        #expect(r.applicants[0].name == "박서준")
        #expect(r.applicants[0].statusLine == "어제 21:40 신청 \u{00B7} 사장님 승인을 기다리고 있어요")
        #expect(r.reason == "학교 시험 기간이라 근무가 어렵습니다.")
        #expect(r.notice == "승인되면 이 근무의 담당자가 박서준으로 바뀌고, 내 스케줄에서 사라져요.")
        #expect(SubstituteRequest.cancelTitle == "대타 요청 취소")
        #expect(r.titleAccessibility == "대타 요청, 10월 12일 월요일, 17:00부터 22:00")
    }

    @Test func 아바타_글자는_서() throws {
        let a = try #require(s.substitute?.applicants.first)
        #expect(PumAvatar.initial(for: a.name) == "서")
    }

    @Test func 조사_받침_규칙() {
        #expect(SubstituteRequest.toParticle("박서준") == "으로")
        #expect(SubstituteRequest.toParticle("김하나") == "로")
        #expect(SubstituteRequest.toParticle("이서울") == "로") // ㄹ 받침
    }

    @Test func 세그먼트_문구() {
        #expect(MyScheduleMode.allCases.map(\.title) == ["목록", "달력"])
    }
}
