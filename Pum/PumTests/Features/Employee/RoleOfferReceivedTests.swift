// UI-IOS-17i · 17k · REQ-014 — 권한 제안 받음: 원문 값 · 읽기 문구 · 처리 중은 누른 버튼만
import Testing
@testable import Pum

struct RoleOfferReceivedTests {
    @Test func 관리자_초대는_원문_값() {
        let s = RoleOfferReceivedState.managerInvite
        #expect(s.sentText == "박민수 · 오늘 11:05" && s.title == "관리자 초대")
        #expect(s.businessText == "종민김밥 본점 · 대표 박민수")
        #expect(s.sections.map(\.title) == ["할 수 있는 것", "할 수 없는 것"])
        #expect(s.sections.map(\.allowed) == [true, false])
        #expect(s.sections[0].rows == ["스케줄 · 근태 · 요청 처리", "급여 확정 · 명세서 발행 · 지급 처리", "직원 정보 · 서류 열람"])
        #expect(s.sections[1].rows == ["대표 변경 · 사업장 삭제", "관리자 지정"])
        #expect(s.pairs.isEmpty)
        #expect(s.footerNotice == "직원으로 일하던 기록과 급여는 그대로예요")
        #expect(RoleOfferReceivedState.acceptTitle == "본인인증 후 수락" && RoleOfferReceivedState.declineTitle == "거절")
    }

    @Test func 대표_권한_이전은_원문_값() {
        let s = RoleOfferReceivedState.ownerTransfer
        #expect(s.sentText == "박민수 · 오늘 10:12" && s.title == "대표 권한 이전")
        #expect(s.sections.count == 1 && s.sections[0].title == "받는 권한" && s.sections[0].allowed)
        #expect(s.sections[0].rows == ["관리자 지정 · 권한 변경", "대표 변경 · 사업장 삭제", "지급 처리 · 강한 인증"])
        #expect(s.pairs == [RoleOfferPair(label: "표시", value: "위임받은 대표"),
                            RoleOfferPair(label: "사업자 대표자", value: "박민수"),
                            RoleOfferPair(label: "박민수", value: "관리자로 남음")])
        #expect(s.footerNotice == "거절하면 지금 그대로예요")
    }

    @Test func 읽기_문구() {
        let s = RoleOfferReceivedState.managerInvite
        #expect(s.sections[0].spoken("스케줄 · 근태 · 요청 처리") == "할 수 있음, 스케줄 · 근태 · 요청 처리")
        #expect(s.sections[1].spoken("대표 변경 · 사업장 삭제") == "할 수 없음, 대표 변경 · 사업장 삭제")
        #expect(s.verifiedReadout == "인증된 사업장, 종민김밥 본점 · 대표 박민수")
        #expect(RoleOfferReceivedState.ownerTransfer.pairs[0].spoken == "표시, 위임받은 대표")
    }

    @Test func 처리_중은_누른_버튼만() {
        let s = RoleOfferReceivedState.managerInvite
        #expect(!s.isResponding)
        let accepting = s.beginning(.accept)
        #expect(accepting?.isLoading(.accept) == true)
        #expect(accepting?.isLoading(.decline) == false)
        #expect(accepting?.beginning(.decline) == nil)
        #expect(accepting?.ended() == s)
        let declining = s.beginning(.decline)
        #expect(declining?.isLoading(.decline) == true && declining?.isLoading(.accept) == false)
    }

    @Test func 인증되지_않은_사업장이면_인증_문구가_없다() {
        let base = RoleOfferReceivedState.managerInvite
        let unverified = RoleOfferReceivedState(sentText: base.sentText, title: base.title, businessText: base.businessText,
                                                sections: base.sections, footerNotice: base.footerNotice, isVerifiedBusiness: false)
        #expect(unverified.verifiedReadout == base.businessText)
        #expect(base.verifiedReadout.hasPrefix("인증된 사업장"))
    }
}
