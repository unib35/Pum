// UI-IOS-19e · REQ-062 — 재직증명서 요청 확인 · 발급: 원문 값 · 발급 가능 조건 · 보낼 값 · 읽기 문구
import Testing
@testable import Pum

struct EmploymentCertIssueTests {
    @Test func 캡처_상태는_원문_값() {
        let s = EmploymentCertIssueState.sample
        #expect(s.senderText == "김하늘 · 오늘 09:12")
        #expect(s.rows.map(\.label) == ["성명", "생년월일", "근무지", "재직 기간", "업무", "용도"])
        #expect(s.rows.map(\.value) == ["김하늘", "2003.05.**", "종민김밥 본점", "2026.3.9 – 현재", "홀 서빙", "금융기관 제출"])
        #expect(s.signLineText == "2026년 10월 7일 · 대표 박민수")
        #expect(s.signatureSubtitle == "박민수 · 2026.3 등록")
        #expect(s.footerNotice == "김하늘님 문서함으로 · 활동 기록에 남아요")
        #expect(s.useRegisteredSignature)
        #expect(!s.issueNextTime)
        #expect(EmploymentCertIssueState.attestation == "위와 같이 재직하고 있음을 증명합니다.")
        #expect(EmploymentCertIssueState.issueNextTimeSubtitle == "기본 항목 · 용도만 다를 때")
    }

    @Test func 발급_가능_조건() {
        #expect(EmploymentCertIssueState.canIssue(useRegisteredSignature: true))
        #expect(!EmploymentCertIssueState.canIssue(useRegisteredSignature: false))
    }

    @Test func 보낼_값() {
        let s = EmploymentCertIssueState.sample
        let c = EmploymentCertIssueChoice(useRegisteredSignature: s.useRegisteredSignature, issueNextTime: s.issueNextTime)
        #expect(c == EmploymentCertIssueChoice(useRegisteredSignature: true, issueNextTime: false))
        #expect(c != EmploymentCertIssueChoice(useRegisteredSignature: true, issueNextTime: true))
    }

    @Test func 읽기_문구() {
        let s = EmploymentCertIssueState.sample
        #expect(s.senderSpoken == "결정 필요, 김하늘, 오늘 09:12")
        #expect(s.rows[0].spoken == "성명, 김하늘")
        #expect(s.signatureSpoken(isOn: true) == "등록된 사업주 서명으로 발급, 박민수 · 2026.3 등록, 선택됨")
        #expect(s.signatureSpoken(isOn: false) == "등록된 사업주 서명으로 발급, 박민수 · 2026.3 등록, 선택 안 됨")
        #expect(s.issueNextTimeSpoken(isOn: false) == "다음부터 바로 발급, 기본 항목 · 용도만 다를 때, 선택 안 됨")
        #expect(s.closingSpoken == "위와 같이 재직하고 있음을 증명합니다. 2026년 10월 7일 · 대표 박민수 사업주 서명")
    }
}
