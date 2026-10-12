// UI-IOS-1i — 근무기록 수정 요청: 글자 수 · 200자 자름 · 보내기 조건 · 문구
import Testing
@testable import Pum

struct EditRequestTests {
    let d = EditRequestDraft.sample

    // 디자인 캡처는 「42 / 200」이지만 예시 문구는 실제로 52자 — 카운터는 실제 글자 수를 따른다
    @Test func 예시_사유_글자_수는_실제_값() {
        #expect(d.reasonCount == 52)
        #expect(d.counterText == "52 / 200")
        #expect(d.counterAccessibility == "200자 중 52자")
    }

    @Test func 글자_수_42() {
        var x = d
        x.reason = String(repeating: "가", count: 42)
        #expect(x.counterText == "42 / 200")
        #expect(x.counterAccessibility == "200자 중 42자")
    }

    @Test func 부제_문구는_en_dash() {
        #expect(d.subtitle == "종민김밥 본점 \u{00B7} 기록된 근무 16:55 \u{2013} 22:00")
    }

    @Test func 퇴근_행_읽기() {
        #expect(d.endRowAccessibility == "퇴근시간, 기록 22:00, 22:30으로 수정")
    }

    @Test func 사람이_보는_200자_초과는_자른다() {
        let long = String(repeating: "가", count: 250)
        #expect(EditRequestDraft.clampedReason(long).count == 200)
        let family = String(repeating: "👨‍👩‍👧", count: 201) // 글자 1개로 보이는 이모지
        #expect(EditRequestDraft.clampedReason(family).count == 200)
        #expect(EditRequestDraft.clampedReason("짧음") == "짧음")
    }

    @Test func 보내기_조건() {
        #expect(d.canSubmit)
        var x = d
        x.reason = ""
        #expect(!x.canSubmit)
        x.reason = "  \n "
        #expect(!x.canSubmit)
        x = d
        x.requestedEnd = x.recordedEnd
        #expect(!x.canSubmit)
    }

    @Test func 경계_200자는_그대로_201자는_200자로() {
        let s200 = String(repeating: "가", count: 200)
        #expect(EditRequestDraft.clampedReason(s200) == s200)
        #expect(EditRequestDraft.clampedReason(s200 + "나").count == 200)
    }

    @Test func 결합_문자는_한_글자로_센다() {
        let flag = "🇰🇷", family = "👨‍👩‍👧"
        let decomposed = "\u{1100}\u{1161}" // NFD 「가」
        #expect((flag + family + decomposed).count == 3)
        let s = String(repeating: flag, count: 201)
        #expect(EditRequestDraft.clampedReason(s) == String(repeating: flag, count: 200))
    }

    @Test func 휠에서_고른_퇴근_시각_반영() {
        let same = d.applying(pickedEnd: d.requestedEnd)
        #expect(same.previewText == d.previewText) // 같은 값이면 서버 미리보기 유지
        let changed = d.applying(pickedEnd: d.requestedEnd + 10)
        #expect(changed.requestedEnd == d.requestedEnd + 10)
        #expect(changed.previewText == nil) // 바뀌면 옛 서버 값 버림
        #expect(d.applying(pickedEnd: -5).requestedEnd == 0)
        #expect(d.applying(pickedEnd: 1440).requestedEnd == 1439)
    }
}
