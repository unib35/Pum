// UI-IOS-19f · REQ-062 — 발급된 재직증명서: 원문 값 · 읽기 문구
import Testing
@testable import Pum

struct EmploymentCertIssuedTests {
    @Test func 원문_값() {
        let s = EmploymentCertIssuedState.sample
        #expect(s.personRows.map(\.label) == ["성명", "생년월일", "근무지", "재직 기간", "업무", "용도"])
        #expect(s.personRows.map(\.value) == ["김하늘", "2003.05.**", "종민김밥 본점", "2026.3.9 – 현재", "홀 서빙", "금융기관 제출"])
        #expect(s.shopRows.map(\.label) == ["상호", "사업자번호", "대표자", "소재지"])
        #expect(s.shopRows.map(\.value) == ["종민김밥 본점", "123-45-67890", "박민수", "대구 수성구 들안로 12"])
        #expect(s.issuedLineText == "10월 7일 10:05 · 금융기관 제출용")
        #expect(s.signLineText == "2026년 10월 7일 · 대표 박민수")
        #expect(s.codeText == "확인 번호 7K4X-92MD")
        #expect(EmploymentCertIssuedState.verifyHint == "받는 곳에서 pum.kr/v 에 넣으면 확인돼요")
        #expect(EmploymentCertIssuedState.backTitle == "문서함")
        #expect(EmploymentCertIssuedState.issuedTitle == "발급됨")
        #expect(EmploymentCertIssuedState.copyTitle == "복사")
        #expect(EmploymentCertIssuedState.shareTitle == "공유")
        #expect(EmploymentCertIssuedState.savePDFTitle == "PDF 저장")
    }

    @Test func 읽기_문구() {
        let s = EmploymentCertIssuedState.sample
        #expect(s.shopRows[0].spoken == "상호, 종민김밥 본점")
        #expect(s.codeSpoken == "확인 번호, 7K4X-92MD")
        #expect(s.issuedSpoken == "발급됨, 10월 7일 10:05 · 금융기관 제출용")
        #expect(s.closingSpoken == "위와 같이 재직하고 있음을 증명합니다. 2026년 10월 7일 · 대표 박민수 사업주 서명")
    }
}
