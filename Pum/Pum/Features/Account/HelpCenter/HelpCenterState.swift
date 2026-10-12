// UI-IOS-6m · REQ-096 — 도움말 · 고객지원 상태. 주제 · 질문 · 운영 시간 · 서비스 상태는 모두 서버 값(let).
// 기기 정보는 화면이 모으지 않는다(오류 신고는 클로저만).
import Foundation

nonisolated struct HelpTopic: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let detail: String
}

nonisolated struct HelpFaq: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
}

/// 서버 상태 단계. 원문에는 「정상 운영 중」만 있어 나머지 단계 글자 · 디자인은 미정(색만 의미 토큰에 맞춤)
nonisolated enum ServiceStatusLevel: Equatable, Sendable {
    case normal, degraded, outage
}

nonisolated struct ServiceStatus: Equatable, Sendable {
    let level: ServiceStatusLevel
    /// 서버가 주는 글자(「정상 운영 중」)
    let text: String
}

/// 문의 · 신고 행 한 줄(제목 + 회색 설명)
nonisolated struct HelpContactRow: Equatable, Sendable {
    let title: String
    let detail: String
}

nonisolated struct HelpCenterState: Equatable, Sendable {
    static let headerTitle = "고객센터"
    static let searchPlaceholder = "무엇을 도와드릴까요?"
    static let faqHeader = "자주 묻는 질문"
    static let statusTitle = "서비스 상태"

    let topics: [HelpTopic]
    let faqs: [HelpFaq]
    let contact: HelpContactRow
    let bugReport: HelpContactRow
    let status: ServiceStatus

    /// 「급여가 이상해요, 계산 근거 확인 · 문의」
    func topicAccessibility(_ t: HelpTopic) -> String { "\(t.title), \(t.detail)" }
    func rowAccessibility(_ r: HelpContactRow) -> String { "\(r.title), \(r.detail)" }
    /// 「서비스 상태, 정상 운영 중」
    var statusAccessibility: String { "\(Self.statusTitle), \(status.text)" }

    static let sample = HelpCenterState(
        topics: [
            HelpTopic(id: "payroll", title: "급여가 이상해요", detail: "계산 근거 확인 · 문의"),
            HelpTopic(id: "attendance", title: "출퇴근이 안 돼요", detail: "QR · 위치 · 오프라인"),
            HelpTopic(id: "contract", title: "계약서 · 서명", detail: "변경 계약 · PDF"),
            HelpTopic(id: "invite", title: "초대 · 사업장", detail: "만료된 초대 · 인증"),
        ],
        faqs: [
            HelpFaq(id: "weekly-holiday", title: "주휴수당은 어떻게 계산되나요?"),
            HelpFaq(id: "forgot-clock-out", title: "퇴근 기록을 깜빡했어요"),
            HelpFaq(id: "multi-workplace", title: "여러 사업장 급여는 따로 받나요?"),
            HelpFaq(id: "owner-edit", title: "사장님이 기록을 바꾸면 알 수 있나요?"),
        ],
        contact: HelpContactRow(title: "1:1 문의하기", detail: "평일 10–18시 · 보통 하루 안에 답변"),
        bugReport: HelpContactRow(title: "오류 신고", detail: "화면 · 기기 정보가 자동으로 첨부돼요"),
        status: ServiceStatus(level: .normal, text: "정상 운영 중")
    )
}
