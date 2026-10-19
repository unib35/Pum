// UI-IOS-2i — 사업장 만들기: 원문 샘플 · 다음 조건 · 한 번만 보내기
import Foundation
import Testing
@testable import Pum

struct WorkplaceCreateTests {
    @Test func 원문_샘플() {
        let s = WorkplaceCreateState.sample
        #expect(s.markText == "종")
        #expect(s.radiusText == "위치 출근 반경 100m")
        #expect(s.paydayText == "매월 10일")
        #expect(s.method == .qrAndLocation)
        #expect(!s.hasBusinessNumber)
        #expect(s.canProceed)
    }

    @Test func 처음은_비어_있고_다음_비활성() {
        let s = WorkplaceCreateState.entry
        #expect(s.markText == "")
        #expect(s.radiusText == nil)
        #expect(!s.canProceed)
    }

    @Test func 이름_업종_주소가_모두_있어야_다음() {
        var s = WorkplaceCreateState.sample
        s.name = "  "
        #expect(!s.canProceed)
        s.name = "가게"; s.category = ""
        #expect(!s.canProceed)
        s.category = "카페"; s.address = ""
        #expect(!s.canProceed)
        s.address = "서울"
        #expect(s.canProceed)
    }

    @Test func 사업자번호는_조건에_넣지_않는다() {
        var s = WorkplaceCreateState.sample
        s.businessNumber = ""
        #expect(s.canProceed)
        s.businessNumber = "123-45-67890"
        #expect(s.hasBusinessNumber)
        #expect(s.canProceed)
    }

    @Test func 한_번만_보내고_실패하면_풀린다() {
        var s = WorkplaceCreateState.sample
        let first = s.beginSubmit()
        #expect(first)
        let second = s.beginSubmit()
        #expect(!second)
        #expect(!s.canProceed)
        s.failSubmit()
        #expect(s.canProceed)
    }

    // DEC-033 — MVP: 이름만 있으면 만든다
    @Test func MVP는_이름만_있으면_다음() {
        var s = WorkplaceCreateState.soloEntry
        #expect(s.isSolo)
        #expect(!s.canProceed)
        s.name = " 품카페 "
        #expect(s.canProceed)
        #expect(s.trimmedName == "품카페")
        let began = s.beginSubmit()
        #expect(began)
        #expect(!s.canProceed)
    }
}
