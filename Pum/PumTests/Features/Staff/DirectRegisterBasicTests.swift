// UI-IOS-20b · REQ-007 — 직접 등록 1/3 기본 정보
import Testing
@testable import Pum

struct DirectRegisterBasicTests {
    @Test func 원문_값() {
        let s = DirectRegisterBasicState.sample
        #expect(s.name == "김민지")
        #expect(s.phone == "010-7731-2048")
        #expect(s.birthDate == "2004. 3. 15")
        #expect(s.startDate == "2026. 7. 1 수")
        #expect(DirectRegisterBasicState.phoneHint == "명세서를 이 번호로 보내요")
        #expect(DirectRegisterBasicState.birthDateHint == "직원이 명세서를 열 때 확인해요")
        #expect(DirectRegisterBasicState.nextTitle == "다음")
    }

    @Test func 필수는_이름과_휴대폰() {
        #expect(DirectRegisterBasicState.canProceed(DirectRegisterBasicState.sample.initialDraft))
        #expect(!DirectRegisterBasicState.canProceed(DirectRegisterBasicState.empty.initialDraft))
        #expect(!DirectRegisterBasicState.canProceed(.init(name: "  ", phone: "010-1")))
        #expect(!DirectRegisterBasicState.canProceed(.init(name: "김민지", phone: "")))
        #expect(!DirectRegisterBasicState.canProceed(.init(name: "김민지", phone: "---")))
    }

    @Test func 생년월일_입사일은_필수가_아니다() {
        var s = DirectRegisterBasicState.sample
        s.birthDate = ""
        s.startDate = ""
        let draft = s.initialDraft
        #expect(DirectRegisterBasicState.canProceed(draft))
    }

    @Test func 휴대폰은_숫자와_하이픈만() {
        #expect(DirectRegisterBasicState.filterPhone("010-7731-2048") == "010-7731-2048")
        #expect(DirectRegisterBasicState.filterPhone("010 7731abc2048+") == "01077312048")
        #expect(DirectRegisterBasicState.filterPhone("０１０") == "")
    }

    @Test func 넘기는_값() {
        let s = DirectRegisterBasicState.sample
        let v = s.value(.init(name: " 김민지 ", phone: "010-7731-2048x"))
        #expect(v == DirectRegisterBasicValue(name: "김민지", phone: "010-7731-2048",
                                              birthDate: "2004. 3. 15", startDate: "2026. 7. 1 수"))
    }

    @Test func 읽기_문구() {
        let s = DirectRegisterBasicState.sample
        #expect(DirectRegisterBasicState.stepReadout == "3단계 중 1단계")
        #expect(DirectRegisterBasicState.phoneLabel == "휴대폰, 명세서를 이 번호로 보내요")
        #expect(DirectRegisterBasicState.birthDateLabel == "생년월일, 직원이 명세서를 열 때 확인해요")
        #expect(s.dateReadout("입사일", hint: nil, value: s.startDate) == "입사일, 2026. 7. 1 수")
        #expect(s.dateReadout("입사일", hint: nil, value: "") == "입사일, 선택")
    }
}
