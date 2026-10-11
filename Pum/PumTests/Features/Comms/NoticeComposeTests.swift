// UI-IOS-3c · REQ-040 — 공지 작성: 원문 값 · 빈 상태 · 보내기 가능 조건 · 버튼 문구 · 칩 순서
import Testing
@testable import Pum

struct NoticeComposeTests {
    @Test func 원문_값() {
        let s = NoticeComposeState.sample
        #expect(s.title == "추석 연휴 영업 안내")
        #expect(s.category == .businessHours)
        #expect(s.allTitle == "전체 5명")
        #expect(s.reminderText == "미확인 직원에게 2일 후 다시 알림")
        #expect(s.requestsReadReceipt)
        #expect(s.recruitment?.summaryText == "10월 5일 12:00 – 20:00 · 2명 · 휴일 1.5배")
        #expect(s.body.contains("10월 6일(화) 휴무"))
    }

    @Test func 카테고리_순서() {
        #expect(NoticeCategory.allCases.map(\.title) == ["영업시간", "회식", "운영 규칙", "교육", "기타"])
    }

    @Test func 빈_상태는_보내기_비활성() {
        let e = NoticeComposeState.empty(totalStaffCount: 3)
        #expect(e.recruitment == nil)
        #expect(e.allTitle == "전체 3명")
        #expect(!e.canSend)
    }

    @Test func 제목과_본문이_있어야_보낼_수_있다() {
        var s = NoticeComposeState.empty(totalStaffCount: 5)
        s.title = "공지"
        #expect(!s.canSend)
        s.body = "  \n "
        #expect(!s.canSend)
        s.body = "내용"
        #expect(s.canSend)
        s.isSending = true
        #expect(!s.canSend)
    }

    @Test func 버튼_문구는_근무_모집_연결에_따라() {
        var s = NoticeComposeState.sample
        #expect(s.sendTitle == "공지 + 근무 모집 보내기")
        s.recruitment = nil
        #expect(s.sendTitle == NoticeComposeState.sendOnlyTitle)
    }
}
