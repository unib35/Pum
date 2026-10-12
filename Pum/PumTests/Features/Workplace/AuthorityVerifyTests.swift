// UI-IOS-5e · REQ-011 — 관리 권한 확인: 원문 샘플 · 문구 · 한 번만
import Foundation
import Testing
@testable import Pum

struct AuthorityVerifyTests {
    @Test func 원문_샘플() {
        let s = AuthorityVerifyState.sample
        #expect(s.choice == .representative)
        #expect(s.representativeDetailPlain == "가입한 이름 박민수와 사업자 대표자명 박민수가 일치해요. 휴대폰 본인확인으로 바로 완료돼요.")
        #expect(s.noteText == "직원 초대·근로계약·급여 확정이 열려요. 급여 이체는 금융 파트너 요건에 따라 추가 확인이 있을 수 있어요.")
        #expect(s.canSubmit)
    }

    @Test func 이름이_다르면_첫_문장을_뺀다() {
        var s = AuthorityVerifyState.sample
        s.namesMatch = false
        #expect(s.representativeDetailPlain == "휴대폰 본인확인으로 바로 완료돼요.")
    }

    @Test func 미리보기_음성_안내() {
        #expect(AuthorityVerifyState.sample.previewAccessibilityText.hasPrefix("인증된 사업장, 완료되면, 본인 박민수 확인, 사업자 영업 중, 권한 대표자. 직원 초대"))
    }

    @Test func 처리_중에는_다시_보내지_않는다() {
        var s = AuthorityVerifyState.sample
        s.isSubmitting = true
        #expect(!s.canSubmit)
    }

    @Test func 조사는_받침에_맞게() {
        #expect(AuthorityVerifyState.particle(after: "박민수", withFinal: "과", withoutFinal: "와") == "와")
        #expect(AuthorityVerifyState.particle(after: "홍길동", withFinal: "과", withoutFinal: "와") == "과")
        #expect(AuthorityVerifyState.particle(after: "홍길동", withFinal: "이", withoutFinal: "가") == "이")
    }
}
