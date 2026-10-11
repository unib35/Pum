// UI-IOS-5c · REQ-011 — 사업자 확인: 숫자만 10자리 · 3-2-5 하이픈 · 활성 조건
import Foundation
import Testing
@testable import Pum

struct BusinessVerifyTests {
    @Test func 원문_샘플() {
        let s = BusinessVerifyState.sample
        #expect(s.formattedNumber == "123-45-67890")
        #expect(s.representative == "박민수")
        #expect(s.openDate == "2024.03.12")
        #expect(s.canSubmit)
    }

    @Test func 숫자만_열자리까지() {
        #expect(BusinessVerifyState.sanitized("123-45-67890") == "1234567890")
        #expect(BusinessVerifyState.sanitized("12a3 4") == "1234")
        #expect(BusinessVerifyState.sanitized("12345678901234") == "1234567890")
        #expect(BusinessVerifyState.sanitized("") == "")
        #expect(BusinessVerifyState.sanitized("٣٤٥") == "")
    }

    @Test func 하이픈_3_2_5() {
        #expect(BusinessVerifyState.formatted("") == "")
        #expect(BusinessVerifyState.formatted("12") == "12")
        #expect(BusinessVerifyState.formatted("123") == "123")
        #expect(BusinessVerifyState.formatted("1234") == "123-4")
        #expect(BusinessVerifyState.formatted("12345") == "123-45")
        #expect(BusinessVerifyState.formatted("123456") == "123-45-6")
        #expect(BusinessVerifyState.formatted("1234567890") == "123-45-67890")
        #expect(BusinessVerifyState.formatted("123-45-67890") == "123-45-67890")
    }

    @Test func 음성_안내는_하이픈_없이_하나씩() {
        #expect(BusinessVerifyState.sample.numberAccessibilityValue == "1 2 3 4 5 6 7 8 9 0")
        #expect(BusinessVerifyState.entry.numberAccessibilityValue == "")
    }

    @Test func 세_칸이_다_있어야_활성() {
        var s = BusinessVerifyState.sample
        #expect(s.isReady)
        s.registrationNumber = "123456789"
        #expect(!s.isReady)
        s = .sample
        s.representative = "  "
        #expect(!s.isReady)
        s = .sample
        s.openDate = ""
        #expect(!s.isReady)
        #expect(!BusinessVerifyState.entry.isReady)
    }

    @Test func 처리_중에는_다시_보내지_않는다() {
        var s = BusinessVerifyState.sample
        s.isSubmitting = true
        #expect(s.isReady)
        #expect(!s.canSubmit)
    }
}
