// UI-IOS-3d · REQ-040 — 공지 확인 현황: 원문 값 · 서버 값 문구 · 버튼 숨김 · 아바타 글자
import Testing
@testable import Pum

struct NoticeReadStatusTests {
    let s = NoticeReadStatusState.sample

    @Test func 원문_값() {
        #expect(s.title == "추석 연휴 영업 안내")
        #expect(s.metaText == "10월 3일 14:20 · 전체 5명")
        #expect(s.readCount == 3 && s.totalCount == 5)
        #expect(s.progressAccessibilityText == "5명 중 3명 확인")
        #expect(s.unreadHeaderText == "미확인 2명")
        #expect(s.readHeaderText == "확인 3명")
    }

    @Test func 막대_비율은_확인수_나누기_전체() {
        #expect(s.progress == 0.6)
        var z = s; z.totalCount = 0
        #expect(z.progress == 0)
    }

    @Test func 행_문구() {
        #expect(s.unread.map(\.detailText) == ["알림 1회 보냄 · 다음 근무 10/5", "알림 1회 보냄 · 다음 근무 10/4"])
        #expect(s.read.map(\.readAtText) == ["10/3 14:31", "10/3 15:02", "10/3 18:44"])
    }

    @Test func 아바타_글자_규칙() {
        #expect(s.unread.map { PumAvatar.initial(for: $0.name) } == ["종", "서"])
        #expect(s.read.map { PumAvatar.initial(for: $0.name) } == ["하", "유", "우"])
    }

    @Test func 근무_모집_문구() throws {
        let r = try #require(s.recruitment)
        #expect(r.prefixText + r.confirmedText + r.suffixText == "10/5 12–20 · 2명 중 1명 확정 · 1명 대기")
    }

    @Test func 버튼_문구는_미확인_목록_길이와_같다() {
        #expect(s.remindTitle == "미확인 2명에게 다시 알림")
    }

    @Test func 미확인_0명이면_버튼을_숨긴다() {
        var n = s; n.unread = []
        #expect(n.remindTitle == nil)
    }
}
