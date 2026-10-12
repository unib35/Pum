// UI-IOS-1i · REQ-006 · REQ-042 · REQ-071 — 근무기록 수정 요청: 입력 상태
// 사업장 확인 기록은 직원이 직접 못 고치고 요청만 보낸다. 승인 전까지는 기존 기록 그대로(REQ-042).
// 「반영되면」 값(인정 근무 · 기본급 차이)은 서버(급여 엔진)가 준 문구를 그대로 보여 준다 — 화면에서 계산하지 않는다.
import Foundation

nonisolated struct EditRequestDraft: Equatable, Sendable {
    static let reasonLimit = 200

    var dateTitle: String
    var workplaceName: String
    /// 하루 안의 분 — 기록된 출퇴근
    var recordedStart: Int
    var recordedEnd: Int
    /// 바꾸려는 퇴근 시각(분)
    var requestedEnd: Int
    /// 서버(엔진)가 준 미리보기 문구, 예: 「인정 근무 +30분 · 기본급 +6,000원」
    /// 시각을 바꾸면 이전 시각 기준 값이라 버린다(새 값은 서버 재조회 후 — 연결 후속). nil이면 「반영되면」 상자를 숨긴다
    var previewText: String?
    var reason: String

    var subtitle: String {
        "\(workplaceName) \u{00B7} 기록된 근무 " + PumFormat.timeRange(HomeFormat.clock(recordedStart), HomeFormat.clock(recordedEnd))
    }
    var recordedStartText: String { HomeFormat.clock(recordedStart) }
    var recordedEndText: String { HomeFormat.clock(recordedEnd) }
    var requestedEndText: String { HomeFormat.clock(requestedEnd) }

    /// 사람이 보는 글자 수
    var reasonCount: Int { reason.count }
    var counterText: String { "\(reasonCount) / \(Self.reasonLimit)" }
    var counterAccessibility: String { "\(Self.reasonLimit)자 중 \(reasonCount)자" }
    var endRowAccessibility: String { "퇴근시간, 기록 \(recordedEndText), \(requestedEndText)으로 수정" }

    var isTimeChanged: Bool { requestedEnd != recordedEnd }
    var hasReason: Bool { !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    /// 사유가 비었거나(공백만) 시간이 기록과 같으면 보낼 수 없다
    var canSubmit: Bool { hasReason && isTimeChanged }

    /// 시간 선택 시트 설정 — 분 단위 입력(기록이 16:55처럼 분 단위라 30분 간격으로는 못 맞춘다)
    static let pickerIntervalMinutes = 1
    /// 시트 제목 · 행 이름은 1i 화면의 기존 문구(「퇴근시간」 · 「기록 22:00」)
    static let pickerTitle = "퇴근시간"
    var pickerRowLabel: String { "기록 \(recordedEndText)" }

    /// C13 시트에서 고른 퇴근 시각 반영(순수). 하루 밖이면 하루 안으로 붙이고, 값이 바뀌면 이전 서버 미리보기는 버린다
    func applying(pickedEnd minutes: Int) -> EditRequestDraft {
        var d = self
        d.requestedEnd = min(max(minutes, 0), 24 * 60 - 1)
        if d.requestedEnd != requestedEnd { d.previewText = nil }
        return d
    }

    /// 200자(사람이 보는 글자)를 넘으면 자른다
    static func clampedReason(_ s: String) -> String {
        s.count > reasonLimit ? String(s.prefix(reasonLimit)) : s
    }
}

extension EditRequestDraft {
    /// 디자인 1i 예시(가짜 값)
    static let sample = EditRequestDraft(
        dateTitle: "9월 30일 수요일", workplaceName: "종민김밥 본점",
        recordedStart: 16 * 60 + 55, recordedEnd: 22 * 60, requestedEnd: 22 * 60 + 30,
        previewText: "인정 근무 +30분 \u{00B7} 기본급 +6,000원",
        reason: "퇴근 버튼을 먼저 눌렀지만 사장님 요청으로 30분 추가 근무했습니다. 마감 정리 도와드렸어요."
    )
}
