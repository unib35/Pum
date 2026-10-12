// UI-IOS-6c · REQ-090 — 약관 및 정책: 원문 값 · 읽기 문구 · 예고 nil이면 띠 없음
import Testing
@testable import Pum

struct PoliciesTests {
    let s = PoliciesState.sample

    @Test func 원문_값() {
        #expect(PoliciesState.headerTitle == "약관 및 정책")
        #expect(s.rows.map(\.title) == ["서비스 이용약관", "개인정보처리방침", "위치기반서비스 이용약관", "개인정보 수집 · 이용 동의",
                                        "개인정보 제3자 제공", "전자문서 · 전자서명 이용", "마케팅 정보 수신", "오픈소스 라이선스"])
        #expect(s.rows.map(\.value) == ["v1.2", "v1.4", "v1.1", "v1.4", "사업장 3곳", "v1.0", "동의 안 함", nil])
        #expect(s.rows[1].detail == "수집 항목 · 이용 목적 · 보관 기간 · 삭제 요청 방법")
        #expect(s.rows[4].detail == "소속 사업장에 근무기록 · 계좌 · 서류가 공유되는 범위")
        #expect(s.rows[5].detail == "근로계약서 · 급여명세서 전자 교부")
        #expect(PoliciesState.footerText == "내가 무엇에 언제 동의했는지는 내 동의 내역에서 확인하고, 선택 동의는 언제든 철회할 수 있어요.")
    }

    @Test func 개인정보처리방침만_강조() {
        #expect(s.rows.filter(\.isEmphasized).map(\.id) == ["privacy"])
    }

    @Test func 읽기_문구() throws {
        let n = try #require(s.notice)
        #expect(s.noticeText(n) == "서비스 이용약관이 2027.01.01부터 바뀌어요")
        #expect(s.noticeAccessibility(n) == "서비스 이용약관이 2027.01.01부터 바뀌어요, 변경 내용")
        #expect(s.rowAccessibility(s.rows[1]) == "개인정보처리방침, 수집 항목 · 이용 목적 · 보관 기간 · 삭제 요청 방법, 버전 1.4")
        #expect(s.rowAccessibility(s.rows[0]) == "서비스 이용약관, 버전 1.2")
        #expect(s.rowAccessibility(s.rows[4]).hasSuffix(", 사업장 3곳"))
        #expect(s.rowAccessibility(s.rows[7]) == "오픈소스 라이선스")
    }

    @Test func 예고가_없으면_띠가_없다() {
        #expect(PoliciesState.sampleNoNotice.notice == nil)
        #expect(PoliciesState.sampleNoNotice.rows == s.rows)
    }
}
