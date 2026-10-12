// UI-IOS-5f · REQ-013 — 직원이 보는 초대: 문구 조합 · 인증 상태별 표시 · 한 번만 참여 잠금
import Testing
@testable import Pum

struct InviteViewTests {
    let s = InviteViewState.sample

    @Test func 원문_문구_조합() {
        #expect(s.titleText == "종민김밥 본점에서\n직원으로 초대했어요")
        #expect(s.subtitleText == "음식점 · 부산 김해시 장유로 12")
        #expect(s.inviterValue == "박민수 · 대표")
        #expect(s.staffValue == "4명 · 2024.03부터 운영")
        #expect(s.wageText == "12,000원")
        #expect(s.initial == "종")
    }

    @Test func 인증됨은_경고_없이_표시들이_보인다() {
        #expect(s.ownerTag == "본인확인")
        #expect(s.operatingTag == "영업 중")
        #expect(s.ownerAccessibility == "대표자, 박민수, 본인확인")
        #expect(s.businessAccessibility == "사업자등록, 123-45-*****, 영업 중")
    }

    @Test func 미인증은_21g_원문_값과_문구() {
        let u = InviteViewState.unverifiedSample
        #expect(!u.isVerified)
        #expect(u.titleText == "종민김밥 율하점에서\n직원으로 초대했어요")
        #expect(u.subtitleText == "음식점 · 김해시 율하로 40")
        #expect(u.initial == "율")
        #expect(u.colorIndex == 2)
        #expect(InviteViewState.unverifiedBadge == "인증 전")
        #expect(u.unverifiedOwnerValue == "확인 전")
        #expect(u.unverifiedBusinessValue == "확인 전")
        #expect(u.unverifiedInviterValue == "박민수")
        #expect(InviteViewState.unverifiedNoticeTitle == "아직 인증되지 않은 사업장이에요")
        #expect(InviteViewState.unverifiedNoticeDetail == "개인정보 제출과 계약 서명은 인증 후에 진행돼요")
        #expect(InviteViewState.unverifiedAllowedNow == "지금은 초대 수락 · 출퇴근 기록")
        #expect(InviteViewState.unverifiedAfterVerify == "인증되면 계약 서명 알림")
    }

    @Test func 미인증은_인증_표시가_숨고_음성_문구가_맞다() {
        let u = InviteViewState.unverifiedSample
        #expect(u.ownerTag == nil)
        #expect(u.operatingTag == nil)
        #expect(u.unverifiedCardAccessibility == "종민김밥 율하점, 인증 전")
    }

    @Test func 사업장_색_번호_방어() {
        var x = s
        for i in [0, -1, -7, 5, 100] { x.colorIndex = i; _ = x.tileColor }
        #expect(x.initial == "종")
    }

    @Test func 참여는_한_번만() {
        var lock = InviteJoinLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        #expect(lock.isSending)
    }

    @Test func 실패하면_다시_누를_수_있다() {
        var lock = InviteJoinLock()
        _ = lock.begin()
        lock.finish(success: false)
        #expect(!lock.isSending)
        let again = lock.begin()
        #expect(again)
    }

    @Test func 성공하면_잠근_채_둔다() {
        var lock = InviteJoinLock()
        _ = lock.begin()
        lock.finish(success: true)
        #expect(lock.isSending)
    }
}
