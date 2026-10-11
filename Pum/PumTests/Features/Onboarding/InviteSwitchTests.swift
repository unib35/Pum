// UI-IOS-2h · REQ-005 — 초대 수락 전환: 문구 조합 · VoiceOver 순서 · 한 번만 수락 잠금
import Testing
@testable import Pum

struct InviteSwitchTests {
    let s = InviteSwitchState.sample

    @Test func 원문_문구_조합() {
        #expect(s.titleLead == "박민수 사장님이")
        #expect(s.titleText == "박민수 사장님이 종민김밥 본점에 초대했어요")
        #expect(s.noteText == "지난 개인 기록은 그대로 남고 사업장 기록으로 옮겨지지 않아요. 10월 급여는 사장님이 사업장 기록으로 계산해요.")
    }

    @Test func 비교_카드_읽기_순서() {
        #expect(s.comparisonAccessibilityText == "지금: 내 기록, 종민김밥, 4~10월 · 86일 기록, 내가 입력 · 자유 수정. 수락 후: 사업장 확인, 종민김밥 본점, 10월 5일부터, 출퇴근 기록 · 수정 요청")
    }

    @Test func 내_설정과_같음은_서버_플래그로만() {
        #expect(s.wageAccessibilityText == "시급, 12,000원, 내 설정과 같음")
        var x = s
        x.wageMatchesMine = false
        #expect(x.wageAccessibilityText == "시급, 12,000원")
    }

    @Test func 수락은_한_번만() {
        var lock = InviteSwitchLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish(success: false)
        #expect(lock.isSending == false)
        let third = lock.begin()
        #expect(third)
        lock.finish(success: true)
        #expect(lock.isSending)
    }
}
