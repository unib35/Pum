// UI-IOS-1ae — 근무기록 확인 요청: 제목 · 부제 · 요약 문구 · 행 문구 · 더 보기 건수
import Testing
@testable import Pum

struct RecordReviewTests {
    let s = RecordReviewState.sample

    @Test func 제목은_두_줄_읽기는_한_문장() {
        #expect(s.titleLines == ["10월 근무기록을", "확인해 주세요"])
        #expect(s.titleText == "10월 근무기록을 확인해 주세요")
    }

    @Test func 부제_조합() {
        #expect(s.subtitlePrefix == "종민김밥 본점 \u{00B7} 박민수 사장님 요청 \u{00B7} ")
        #expect(s.subtitleText == "종민김밥 본점 \u{00B7} 박민수 사장님 요청 \u{00B7} 10월 31일까지 회신")
    }

    @Test func 메시지_카드_읽기() {
        #expect(s.messageAccessibilityText.hasPrefix("사장님 메시지, \u{201C}11월 10일 급여 확정 전에"))
    }

    @Test func 요약_문구는_서버_값_그대로() {
        #expect(s.daysText == "17일")
        #expect(s.recognizedText == "82시간 30분")
        #expect(s.payText == "1,188,000")
        #expect(s.countLead + s.normalText == "기록 17건 중 16건 정상")
        #expect(s.attentionText == "1건 살펴보세요")
    }

    @Test func 살펴볼_것_0건이면_오른쪽_문구_없음() {
        var x = s
        x.attentionCount = 0
        #expect(x.attentionText == nil)
    }

    @Test func 행_문구() {
        let attention = s.rows[0], a = s.rows[1], b = s.rows[2]
        #expect(attention.titleText == "대타 \u{00B7} 박서준이 근무")
        #expect(attention.detailText == "내 기록에서 제외됨 \u{00B7} 0원")
        #expect(attention.trailingText == "확인")
        #expect(a.titleText == "16:57 \u{2013} 22:04")
        #expect(a.detailText == "인정 4시간 37분 \u{00B7} 55,400원")
        #expect(b.titleText == "17:00 \u{2013} 22:00")
        #expect(b.detailText == "인정 4시간 30분 \u{00B7} 54,000원")
        #expect(a.trailingText == "확정")
    }

    @Test func 행_읽기는_한_문장() {
        #expect(s.rows[0].accessibilityText == "10월 12일 월요일, 대타, 박서준이 근무, 내 기록에서 제외됨, 0원, 확인 필요")
        #expect(s.rows[1].accessibilityText == "10월 30일 금요일, 16:57부터 22:04까지, 인정 4시간 37분, 55,400원, 확정")
    }

    @Test func 더_보기_건수는_전체_빼기_보이는_행() {
        #expect(s.moreCount == 14)
        #expect(s.moreText == "14건 더 보기")
        var x = s
        x.totalCount = 3
        #expect(x.moreText == nil)
    }
}
