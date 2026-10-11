// UI-IOS-5b · REQ-010 — 인증 시트: 단계 상태 · 문구 · VoiceOver 말
import Testing
@testable import Pum

struct VerifyIntroTests {
    let s = VerifyIntroState.sample

    @Test func 원문_세_단계_순서와_상태() {
        #expect(s.steps.map(\.title) == ["본인 확인", "사업자 확인", "관리 권한 확인"])
        #expect(s.steps.map(\.status) == [.done, .current, .upcoming])
    }

    @Test func 부제는_원문_그대로() {
        #expect(s.steps[0].subtitle == "가입 시 휴대폰 인증 완료 \u{00B7} 박민수")
        #expect(s.steps[1].subtitle == "사업자등록번호 \u{00B7} 대표자명 \u{00B7} 개업일")
        #expect(s.steps[2].subtitle == "대표자 본인이거나, 대표자에게 위임받은 관리자")
    }

    @Test func VoiceOver_단계_말() {
        #expect(s.steps[0].accessibilityLabel(number: 1) == "1단계 본인 확인, 완료")
        #expect(s.steps[1].accessibilityLabel(number: 2) == "2단계 사업자 확인, 지금 단계")
        #expect(s.steps[2].accessibilityLabel(number: 3) == "3단계 관리 권한 확인")
    }

    @Test func 제목과_설명_문구() {
        #expect(VerifyIntroState.sheetTitle == "직원을 초대하려면\n사업장 인증이 필요해요")
        #expect(VerifyIntroState.sheetBody.hasSuffix("약 2분 걸려요."))
        #expect(s.qrCaption == "종민김밥 본점 초대 QR")
    }

    @Test func 사업장_이름은_서버_값을_따른다() {
        var t = s
        t.workplaceName = "새 가게"
        #expect(t.qrCaption == "새 가게 초대 QR")
    }
}
