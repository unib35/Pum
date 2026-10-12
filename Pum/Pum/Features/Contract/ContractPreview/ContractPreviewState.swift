// UI-IOS-10b · REQ-060 — 계약서 미리보기 → 사업주 서명 후 보내기(2/2 단계).
// 계약서 제목 · 본문 · 조항 · 쪽 수 · 단계 문구 · 단계 완료 여부는 서버 값 그대로 — 화면에서 근로조건으로 조항을 만들지 않는다.
// 서명하고 보내기는 되돌릴 수 없다: 한 번만, 처리 중 잠금, 실패일 때만 푼다(성공이면 잠근 채 부르는 쪽이 화면을 바꾼다).
import Foundation

/// 번호 목록 한 줄. note가 있으면 둘째 줄(번호 너비만큼 들여씀)
nonisolated struct ContractPreviewClause: Equatable, Sendable, Identifiable {
    var id: Int
    /// 「1.」
    var number: String
    var text: String
    /// 「(휴게 30분, 주 소정근로 18시간)」
    var note: String?

    var spoken: String { [number, text, note].compactMap { $0 }.joined(separator: " ") }
}

/// 서명 · 보관 단계 한 행. isDone은 서버 값
nonisolated struct ContractPreviewStep: Equatable, Sendable, Identifiable {
    var id: Int
    var title: String
    var detail: String
    var isDone: Bool

    var spoken: String { "\(title), \(detail), \(isDone ? "완료" : "아직 안 함")" }
}

nonisolated struct ContractPreviewState: Equatable, Sendable {
    static let screenTitle = "근로계약서"
    static let stepText = "2/2"
    static let stepSpoken = "2단계 중 2단계"
    static let fullTextTitle = "전문 보기"
    static let signTitle = "서명하고 보내기"
    static let sendingTitle = "보내는 중"
    static let footnote = "직원이 서명해야 계약이 시작돼요"

    var docTitle: String
    var intro: String
    var clauses: [ContractPreviewClause]
    /// 「1 / 3쪽」
    var pageText: String
    var steps: [ContractPreviewStep]

    /// 원문 값
    static let sample = ContractPreviewState(
        docTitle: "단시간근로자 표준근로계약서",
        intro: "종민김밥 본점(이하 \"사업주\")과 김하늘(이하 \"근로자\")은 다음과 같이 근로계약을 체결한다.",
        clauses: [
            ContractPreviewClause(id: 1, number: "1.", text: "근로개시일 : 2026년 10월 6일부터", note: nil),
            ContractPreviewClause(id: 2, number: "2.", text: "근무장소 : 서울 마포구 양화로 12, 종민김밥 본점", note: nil),
            ContractPreviewClause(id: 3, number: "3.", text: "업무내용 : 주방 보조 \u{00B7} 홀 서빙", note: nil),
            ContractPreviewClause(id: 4, number: "4.", text: "근로일 \u{00B7} 근로시간 : 월 \u{00B7} 수 \u{00B7} 금 \u{00B7} 토 17:00 \u{2013} 22:00",
                                  note: "(휴게 30분, 주 소정근로 18시간)"),
            ContractPreviewClause(id: 5, number: "5.", text: "임금 : 시급 11,500원, 매월 10일 근로자 계좌로 지급", note: nil),
            ContractPreviewClause(id: 6, number: "6.", text: "주휴일 : 매주 일요일", note: nil),
        ],
        pageText: "1 / 3쪽",
        steps: [
            ContractPreviewStep(id: 1, title: "사업주 서명", detail: "지금 \u{00B7} 휴대폰 본인확인 후", isDone: false),
            ContractPreviewStep(id: 2, title: "김하늘 서명", detail: "소식 탭에 요청으로 도착", isDone: false),
            ContractPreviewStep(id: 3, title: "양쪽 문서함에 보관", detail: "서명 완료본 PDF", isDone: false),
        ])
}

/// 「서명하고 보내기」 한 번만 — 누르면 잠그고, 실패일 때만 푼다
nonisolated struct ContractPreviewLock: Equatable, Sendable {
    private(set) var isSending = false
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    /// 성공이면 잠근 채 둔다(화면 전환은 부르는 쪽)
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
