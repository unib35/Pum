// UI-IOS-10a — 근로조건 입력: 결과 basis 일치 판단 · 요일 토글 · 최저임금 비교(서버 값) · 미리보기 활성
import Testing
@testable import Pum

struct WorkTermsInputTests {
    @Test func 원문_값은_결과가_현재() {
        let s = WorkTermsInputState.sample
        #expect(s.resultIsCurrent)
        #expect(s.weeklyText == "18시간")
        #expect(s.benefitsText == "주휴수당 \u{00B7} 4대보험 적용 대상")
        #expect(s.requiredText == "필수 기재 항목 8개 입력됨")
        #expect(s.minimumWageText == "최저임금 10,320원 이상")
        #expect(s.wageText == "11,500원")
        #expect(s.timeText == "17:00 \u{2013} 22:00")
        #expect(s.breakText == "30분")
        #expect(s.canPreview)
    }

    @Test func 입력이_바뀌면_서버_값을_숨긴다() {
        var s = WorkTermsInputState.sample
        s.inputs.hourlyWon = 12_000
        #expect(!s.resultIsCurrent)
        #expect(s.weeklyText == nil)
        #expect(s.benefitsText == nil)
        #expect(s.requiredText == nil)
        #expect(s.breakNotice == nil)
        #expect(!s.canPreview)
        // 최저임금 기준값은 입력과 무관해 남는다
        #expect(s.minimumWageText == "최저임금 10,320원 이상")
    }

    @Test func 결과가_없으면_숨김() {
        var s = WorkTermsInputState.sample
        s.result = nil
        #expect(s.weeklyText == nil)
        #expect(s.minimumWageText == nil)
        #expect(!s.isBelowMinimumWage)
        #expect(!s.canPreview)
    }

    @Test func 요일_토글() {
        var s = WorkTermsInputState.sample
        #expect(s.isWeekdaySelected(1))
        #expect(!s.isWeekdaySelected(2))
        s.toggleWeekday(2)
        #expect(s.isWeekdaySelected(2))
        s.toggleWeekday(1)
        #expect(!s.isWeekdaySelected(1))
        #expect(s.inputs.weekdays == [2, 3, 5, 6])
    }

    @Test func 최저임금_미만_판단은_서버_값과_비교() {
        var s = WorkTermsInputState.sample
        #expect(!s.isBelowMinimumWage)
        s.inputs.hourlyWon = 10_320
        #expect(!s.isBelowMinimumWage)
        s.inputs.hourlyWon = 10_319
        #expect(s.isBelowMinimumWage)
    }

    @Test func 미리보기는_서버_canPreview일_때만() {
        var s = WorkTermsInputState.sample
        s.result?.canPreview = false
        #expect(!s.canPreview)
        s.result?.canPreview = true
        #expect(s.canPreview)
    }

    @Test func 시간_시트_적용은_시간과_휴게만() {
        var s = WorkTermsInputState.sample
        var v = s.pickerValue
        v.startMinutes = 18 * 60
        v.breakMinutes = 60
        v.weekdays = [7]
        s.apply(picked: v)
        #expect(s.inputs.startMinutes == 18 * 60)
        #expect(s.breakText == "1시간")
        #expect(s.inputs.weekdays == [1, 3, 5, 6])
    }

    @Test func 읽기_문구() {
        let s = WorkTermsInputState.sample
        #expect(s.wageSpoken == "시급, 11,500원, 최저임금 10,320원 이상")
        #expect(WorkTermsInputState.durationText(minutes: 18 * 60 + 30) == "18시간 30분")
    }
}
