// UI-IOS-2c — 시작 방식: 선택지 문구 · 순서, 선택 전환, 다음 버튼 활성 조건, 원문 캡처 상태
import Testing
@testable import Pum

struct StartChoiceTests {
    @Test func 선택지_3개_순서와_문구() {
        #expect(StartChoice.allCases == [.personal, .inviteCode, .owner])
        #expect(StartChoice.personal.title == "혼자 기록할게요")
        #expect(StartChoice.inviteCode.title == "초대 코드가 있어요")
        #expect(StartChoice.owner.title == "사장님이에요")
        #expect(StartChoice.inviteCode.detail == "사장님께 받은 링크·QR·6자리 코드로 사업장에 참여해요.")
    }

    @Test func 기능_태그는_개인_모드만() {
        #expect(StartChoice.personal.tags == ["근무 캘린더", "급여 계산기", "출퇴근 기록"])
        #expect(StartChoice.inviteCode.tags.isEmpty)
        #expect(StartChoice.owner.tags.isEmpty)
    }

    @Test func 실제_진입은_선택_없음_다음_비활성() {
        let s = StartChoiceState()
        #expect(s.selected == nil)
        #expect(!s.isNextEnabled)
    }

    @Test func 택일_전환() {
        var s = StartChoiceState()
        s.select(.owner)
        let afterOwner = s
        #expect(afterOwner.isSelected(.owner))
        #expect(afterOwner.isNextEnabled)
        s.select(.inviteCode)
        let afterInvite = s
        #expect(afterInvite.isSelected(.inviteCode))
        #expect(!afterInvite.isSelected(.owner))
    }

    @Test func 원문_캡처_상태는_혼자_기록() {
        #expect(StartChoiceState.sample.selected == .personal)
        #expect(StartChoiceState.sample.isNextEnabled)
    }

    @Test func 접근성_문장() {
        let s = StartChoiceState.sample
        #expect(s.accessibilityValue(for: .personal) == "3개 중 1번째, 선택됨")
        #expect(s.accessibilityValue(for: .owner) == "3개 중 3번째")
        #expect(s.accessibilityLabel(for: .personal).hasSuffix("기능: 근무 캘린더, 급여 계산기, 출퇴근 기록"))
        #expect(s.accessibilityLabel(for: .owner) == "사장님이에요, 사업장을 만들고 직원을 초대해요. 사업자 정보는 나중에 입력해도 돼요.")
    }
}
