// UI-IOS-20a · REQ-007 — 직원 추가 시트: 원문 값 · 다음 가능 조건 · 읽기 문구
import Testing
@testable import Pum

struct StaffAddTests {
    @Test func 원문_값() {
        #expect(StaffAddState.title == "직원 추가")
        #expect(StaffAddMethod.invite.title == "초대 보내기")
        #expect(StaffAddMethod.invite.detail == "직원이 앱으로 출퇴근해요 · 기록은 직원이 남겨요")
        #expect(StaffAddMethod.direct.title == "직접 등록")
        #expect(StaffAddMethod.direct.detail == "앱 없이 시작해요 · 근무는 사장님이 기록해요")
        #expect(StaffAddState.notice == "직접 등록한 직원도 나중에 초대할 수 있어요. 그동안의 기록은 그대로 이어져요.")
        #expect(StaffAddState.nextTitle == "다음")
        #expect(StaffAddState.sample.initialSelection == .direct)
    }

    @Test func 선택이_있어야_다음() {
        let s = StaffAddState.sample
        #expect(!s.canNext(nil))
        #expect(s.canNext(.invite))
        #expect(s.canNext(.direct))
    }

    @Test func 읽기_문구() {
        #expect(StaffAddMethod.direct.readout == "직접 등록, 앱 없이 시작해요 · 근무는 사장님이 기록해요")
        #expect(StaffAddMethod.invite.readout == "초대 보내기, 직원이 앱으로 출퇴근해요 · 기록은 직원이 남겨요")
    }
}
