// UI-IOS-19i · REQ-030 — 휴게 못 씀 확인: 원문 값 · 경고 없을 때 · 읽기 문구
import Testing
@testable import Pum

struct BreakReviewTests {
    @Test func 캡처_상태는_원문_값() {
        let s = BreakReviewState.sample
        #expect(s.senderText == "김하늘 · 어제 22:10")
        #expect(s.shiftText == "10월 6일 화 · 17:00 – 22:00")
        #expect(s.plannedText == "30분")
        #expect(s.actualText == "0분")
        #expect(s.reasonText == "주문이 몰려서")
        #expect(s.workedChangeText == "4h 30m → 5h 00m")
        #expect(s.costBasisText == "소정근로 초과 가산 포함")
        #expect(s.costText == "+9,000원")
        #expect(s.repeatTitle == "김하늘 · 이번 달 3번째")
        #expect(s.repeatWarning?.lawText == "4시간 이상 근무에는 휴게 30분 이상 · 근로기준법 54조")
        #expect(s.footerNotice == "김하늘님에게 알림 · 원래 기록은 이력으로 남아요")
        #expect(BreakReviewState.otherTimeTitle == "다른 시간으로")
        #expect(BreakReviewState.approveTitle == "인정")
    }

    @Test func 반복_경고가_없으면_없다() {
        let s = BreakReviewState.sampleNoWarning
        #expect(s.repeatWarning == nil)
        #expect(s.repeatTitle == nil)
        #expect(s.repeatSpoken == nil)
    }

    @Test func 읽기_문구() {
        let s = BreakReviewState.sample
        #expect(s.workedSpoken == "인정 근무, 4시간 30분에서 5시간으로")
        #expect(s.breakTilesSpoken == "예정 휴게 30분, 실제 0분")
        #expect(s.costSpoken == "예상 인건비, 소정근로 초과 가산 포함, +9,000원")
        #expect(s.repeatSpoken == "김하늘 · 이번 달 3번째, 4시간 이상 근무에는 휴게 30분 이상 · 근로기준법 54조")
        #expect(s.sentSpoken == "확인 필요, 김하늘 · 어제 22:10")
    }
}
