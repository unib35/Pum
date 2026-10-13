// UI-IOS-2l — 요약 줄 · 서류 음성 안내 · 비상 연락처 · 계좌 숨김 규칙
import Testing
@testable import Pum

struct StaffDetailTests {
    let s = StaffDetailState.sample

    @Test func 요약_줄은_서버_값과_정수_원() {
        #expect(s.summaryText == "홀 서빙\u{00B7}마감 \u{00B7} 2026.10.05 입사 \u{00B7} 시급 12,000원")
    }

    @Test func 서류_상태와_색_종류() {
        #expect(s.documents.map(\.statusText) == ["갱신 예정", "완료", "완료", "미제출"])
        #expect(s.documents.map(\.tone) == [.attention, .done, .done, .missing])
    }

    @Test func 서류_음성_안내() {
        #expect(s.documents[0].accessibilityText == "보건증, 2026년 11월 14일 만료, 42일 남음, 갱신 예정")
        #expect(s.documents[1].accessibilityText == "근로계약서, 2026년 10월 3일 양측 서명, PDF, 완료")
        #expect(s.documents[3].accessibilityText == "통장 사본, 아직 안 받음, 미제출")
    }

    @Test func 계좌는_서버가_가린_값_그대로() {
        #expect(s.maskedAccount == "카카오뱅크 3333-**-****821" && s.hasAccount)
    }

    @Test func 비상_연락처와_계좌가_없으면_행을_숨김() {
        var n = s
        n.emergencyPhone = nil
        n.maskedAccount = ""
        #expect(!n.hasEmergency && !n.hasAccount)
        #expect(s.hasEmergency)
        #expect(s.emergencyAccessibilityText == "비상 연락처, 010-2210-9981, 어머니")
    }

    @Test func 연락_버튼_음성_안내() {
        #expect(s.callAccessibilityLabel == "이종민에게 전화")
        #expect(s.kakaoAccessibilityLabel == "이종민에게 카카오톡")
    }
}
