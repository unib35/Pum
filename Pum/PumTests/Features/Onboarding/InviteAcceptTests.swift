// UI-IOS-1o — 초대 수락: 제목 문장 · 사업장 부제 · 근로조건 6행 · 빈 값 생략
import Testing
@testable import Pum

struct InviteAcceptTests {
    let r = InviteAcceptRecord.sample

    @Test func 제목_문장_조합() {
        #expect(r.titleText == "박민수 사장님이 종민김밥 본점에 초대했어요")
        var x = r; x.ownerName = "김하나"; x.workplaceName = "하나분식"
        #expect(x.titleText == "김하나 사장님이 하나분식에 초대했어요")
    }

    @Test func 사업장_부제() {
        #expect(r.subtitleText == "부산 김해시 장유로 12 · 음식점 · 직원 4명")
    }

    @Test func 근로조건_6행_순서_문구() {
        #expect(r.visibleTerms.map(\.label) == ["급여 형태", "기본 근무일", "기본 근무시간", "휴게시간", "급여일", "출퇴근 방식"])
        #expect(r.visibleTerms.map(\.value) == ["시급 12,000원", "월 · 수 · 금", "17:00 – 22:00", "30분", "매월 10일", "매장 QR + 위치 확인"])
        #expect(r.visibleTerms[0].accessibilityText == "급여 형태, 시급 12,000원")
    }

    @Test func 빈_값_행은_생략() {
        var x = r
        x.terms[3] = .init(label: "휴게시간", value: "  ")
        #expect(x.visibleTerms.count == 5)
        #expect(!x.visibleTerms.map(\.label).contains("휴게시간"))
    }
}
