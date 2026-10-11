// UI-IOS-3b · REQ-040 — 공지 상세: 원문 값 · 확인 현황 · 근무 모집 문구(서버 값 그대로) · 접근성 본문 순서
import Testing
@testable import Pum

struct NoticeDetailTests {
    let s = NoticeDetailState.sample

    @Test func 원문_값() {
        #expect(s.title == "추석 연휴 영업 안내")
        #expect(s.audienceLabel == "전체 직원")
        #expect(s.authorName == "박민수 사장님")
        #expect(s.postedAtText == "2026.10.03 14:20")
        #expect(s.myReadText == "읽음 · 오늘 15:02")
    }

    @Test func 확인_현황은_서버_값_그대로() {
        #expect(s.readStatusText == "직원 5명 중 3명 확인")
    }

    @Test func 근무_모집_문구() throws {
        let r = try #require(s.recruitment)
        #expect(r.countText == "2명 모집 · 1명 신청")
        #expect(r.dateTimeText == "10월 5일 월 · 12:00 – 20:00")
        #expect(r.detailText == "휴게 1시간 · 인정 7시간 · 휴일 1.5배 · 예상 126,000원")
        #expect(r.expectedPay == 126_000)
    }

    @Test func 본문은_강조_구분없이_읽는다() {
        #expect(s.bodyAccessibilityText == """
        추석 연휴 영업시간 안내드립니다.
        10월 5일(월) 12:00 – 20:00 단축 영업
        10월 6일(화) 휴무
        10월 7일(수) 정상 영업
        5일은 예약이 많아 추가 인력이 필요합니다. 가능하신 분은 아래 근무 모집에서 신청해 주세요. 모두 확인 부탁드립니다.
        """)
        #expect(s.paragraphs[1].lines.compactMap(\.strong) == ["10월 5일(월)", "10월 6일(화)", "10월 7일(수)"])
    }

    @Test func 작성자_아바타_글자() {
        #expect(PumAvatar.initial(for: s.authorName) == "박")
    }
}
