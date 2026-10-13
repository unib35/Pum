// UI-IOS-6m · REQ-096 — 고객센터: 원문 값 · 읽기 문구 · 상태별 글자
import Testing
@testable import Pum

struct HelpCenterTests {
    let s = HelpCenterState.sample

    @Test func 원문_값() {
        #expect(HelpCenterState.headerTitle == "고객센터")
        #expect(HelpCenterState.searchPlaceholder == "무엇을 도와드릴까요?")
        #expect(HelpCenterState.faqHeader == "자주 묻는 질문")
        #expect(s.topics.map(\.title) == ["급여가 이상해요", "출퇴근이 안 돼요", "계약서 · 서명", "초대 · 사업장"])
        #expect(s.topics.map(\.detail) == ["계산 근거 확인 · 문의", "QR · 위치 · 오프라인", "변경 계약 · PDF", "만료된 초대 · 인증"])
        #expect(s.faqs.map(\.title) == ["주휴수당은 어떻게 계산되나요?", "퇴근 기록을 깜빡했어요",
                                        "여러 사업장 급여는 따로 받나요?", "사장님이 기록을 바꾸면 알 수 있나요?"])
        #expect(s.contact == HelpContactRow(title: "1:1 문의하기", detail: "평일 10–18시 · 보통 하루 안에 답변"))
        #expect(s.bugReport == HelpContactRow(title: "오류 신고", detail: "화면 · 기기 정보가 자동으로 첨부돼요"))
        #expect(HelpCenterState.statusTitle == "서비스 상태")
    }

    @Test func 읽기_문구() {
        #expect(s.topicAccessibility(s.topics[0]) == "급여가 이상해요, 계산 근거 확인 · 문의")
        #expect(s.rowAccessibility(s.contact) == "1:1 문의하기, 평일 10–18시 · 보통 하루 안에 답변")
        #expect(s.statusAccessibility == "서비스 상태, 정상 운영 중")
    }

    @Test func 상태별_글자는_서버_값() {
        #expect(s.status == ServiceStatus(level: .normal, text: "정상 운영 중"))
        let down = HelpCenterState(topics: s.topics, faqs: s.faqs, contact: s.contact, bugReport: s.bugReport,
                                   status: ServiceStatus(level: .outage, text: "점검 중"))
        #expect(down.statusAccessibility == "서비스 상태, 점검 중")
    }
}
