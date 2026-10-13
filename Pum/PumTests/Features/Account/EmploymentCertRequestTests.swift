// UI-IOS-19d · REQ-062 — 재직증명서 요청: 원문 값 · 보낼 값 · 읽기 문구
import Testing
@testable import Pum

struct EmploymentCertRequestTests {
    @Test func 원문_값() {
        let s = EmploymentCertRequestState.sample
        #expect(s.rows.map(\.title) == ["이름", "근무지", "재직 기간", "업무"])
        #expect(s.rows.map(\.value) == ["김하늘", "종민김밥 본점", "2026.3.9 – 현재", "홀 서빙"])
        #expect(s.initialDraft == .init(includesBirthDate: true, includesAddress: false, purpose: .financial))
        #expect(EmploymentCertPurpose.allCases.map(\.title) == ["금융기관", "관공서", "기타"])
        #expect(EmploymentCertRequestState.sendTitle == "사장님께 요청")
        #expect(EmploymentCertRequestState.footerNotice == "발급되면 알림 · 문서함에 보관돼요")
    }

    @Test func 보낼_값에_토글_용도_반영() {
        let s = EmploymentCertRequestState.sample
        #expect(s.value(s.initialDraft) == .init(includesBirthDate: true, includesAddress: false, purpose: .financial))
        var d = s.initialDraft
        d.includesBirthDate = false
        d.includesAddress = true
        d.purpose = .other
        let v = s.value(d)
        #expect(v == .init(includesBirthDate: false, includesAddress: true, purpose: .other))
    }

    @Test func 읽기_문구() {
        let s = EmploymentCertRequestState.sample
        #expect(s.toggleReadout("생년월일", isOn: true) == "생년월일, 켬")
        #expect(s.toggleReadout("주소", isOn: false) == "주소, 끔")
        #expect(s.purposeReadout(.financial, draft: s.initialDraft) == "금융기관, 선택됨")
        #expect(s.purposeReadout(.government, draft: s.initialDraft) == "관공서")
        #expect(s.infoReadout(s.rows[0]) == "이름, 김하늘")
    }
}
