// UI-IOS-6o · REQ-090 — 개인정보 · 앱 정보: 원문 값 · 읽기 문구 · 버전 행은 누르지 않음
import Testing
@testable import Pum

struct PrivacyAppInfoTests {
    let s = PrivacyAppInfoState.sample

    @Test func 원문_값() {
        #expect(PrivacyAppInfoState.headerTitle == "개인정보 · 앱 정보")
        #expect(s.sections.map(\.title) == ["개인정보 관리", "앱 정보"])
        #expect(s.sections[0].rows.map(\.title) == ["내 정보 확인", "내 데이터 다운로드", "동의 내역", "연결된 사업장", "제출한 서류", "계정 삭제"])
        #expect(s.sections[0].rows.map(\.value) == [nil, nil, nil, "3곳", "4건", nil])
        #expect(s.sections[0].rows[1].detail == "근무기록 · 명세서 · 계약서 ZIP · 메일로 받기")
        #expect(s.sections[1].rows.map(\.title) == ["앱 버전", "공지사항", "서비스 이용약관", "개인정보처리방침", "오픈소스 라이선스", "운영사 정보"])
        #expect(s.sections[1].rows[0].value == "1.0.0 · 최신")
    }

    @Test func 강조와_위험() {
        let all = s.sections.flatMap(\.rows)
        #expect(all.filter(\.isEmphasized).map(\.title) == ["개인정보처리방침"])
        #expect(all.filter(\.isDanger).map(\.title) == ["계정 삭제"])
    }

    @Test func 버전_행은_누르지_않는다() {
        let all = s.sections.flatMap(\.rows)
        #expect(all.filter { !$0.isTappable }.map(\.id) == ["version"])
    }

    @Test func 읽기_문구() {
        let all = s.sections.flatMap(\.rows)
        #expect(s.rowAccessibility(all[3]) == "연결된 사업장, 3곳")
        #expect(s.rowAccessibility(all[1]) == "내 데이터 다운로드, 근무기록 · 명세서 · 계약서 ZIP · 메일로 받기")
        #expect(s.rowAccessibility(s.sections[1].rows[0]) == "앱 버전, 1.0.0 · 최신")
        #expect(s.rowAccessibility(all[0]) == "내 정보 확인")
    }
}
