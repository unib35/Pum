// UI-IOS-6b · REQ-090 — 회원 탈퇴: 유일한 대표(Owner)면 소유권 이전 먼저.
// 정리할 사업장 · 안내 문구 · 보관 기간(「3년」 · 「30일」)은 서버 값 그대로. 법정 값을 화면이 정하지 않는다.
import Foundation

/// 문장 안의 한 토막. 굵은 부분만 표시(원문 「3년간 분리 보관」)
nonisolated struct WithdrawTextRun: Equatable, Sendable {
    var text: String
    var isBold: Bool = false
}

nonisolated struct WithdrawNoticeItem: Equatable, Sendable, Identifiable {
    var id: String
    var runs: [WithdrawTextRun]

    var plainText: String { runs.map(\.text).joined() }

    var attributed: AttributedString {
        var result = AttributedString()
        for run in runs {
            var piece = AttributedString(run.text)
            if run.isBold { piece.inlinePresentationIntent = .stronglyEmphasized }
            result += piece
        }
        return result
    }
}

/// 탈퇴 전에 정리해야 하는 사업장(서버가 준 목록)
nonisolated struct WithdrawWorkplace: Equatable, Sendable, Identifiable {
    var id: String
    /// 타일 글자 「종」
    var initial: String
    var name: String
    /// 「박민수님이 유일한 대표(Owner)예요」(주황)
    var statusText: String
    /// 「계정을 삭제하기 전에 … 직원 4명의 근무·급여 기록이 연결되어 있어요.」
    var message: String

    var spoken: String { "\(name), \(statusText), \(message)" }
}

nonisolated struct WithdrawState: Equatable, Sendable {
    static let headingFirstLine = "탈퇴하기 전에"
    static let headingSecondLine = "정리할 게 있어요"
    static let transferTitle = "소유권 이전"
    static let closeTitle = "사업장 종료"

    /// 정리할 사업장. 하나라도 남아 있으면 탈퇴 버튼은 비활성
    var workplaces: [WithdrawWorkplace]
    /// 「탈퇴하면」
    var consequencesTitle: String
    var consequences: [WithdrawNoticeItem]
    /// 「직원으로 소속된 사업장이 있다면 …」
    var staffNote: String
    /// 하단 버튼 글자(서버 값). 비활성일 땐 이유 문장
    var withdrawTitle: String
    /// 서버가 정리할 사업장 목록을 다 받았는지 — 받기 전 · 실패면 빈 목록이어도 탈퇴할 수 없다(되돌릴 수 없는 일)
    var isLoaded: Bool = true
    /// 탈퇴 요청을 보내는 중 — 두 번 보내지 않게 버튼을 잠근다
    var isSubmitting: Bool = false

    var canWithdraw: Bool { isLoaded && workplaces.isEmpty && !isSubmitting }

    /// 비활성 버튼을 읽을 때 붙이는 이유(원문 없음 — 화면에 보이지 않는 VoiceOver 힌트만)
    var blockedReason: String? {
        workplaces.isEmpty ? nil : "정리할 사업장이 \(workplaces.count)곳 남아 있어요"
    }

    /// 원문 값
    static let sample = WithdrawState(
        workplaces: [
            .init(id: "jongmin-main", initial: "종", name: "종민김밥 본점",
                  statusText: "박민수님이 유일한 대표(Owner)예요",
                  message: "계정을 삭제하기 전에 사업장 소유권을 다른 관리자에게 넘기거나 사업장을 종료해주세요. 직원 4명의 근무\u{00B7}급여 기록이 연결되어 있어요."),
        ],
        consequencesTitle: "탈퇴하면",
        consequences: [
            .init(id: "delete", runs: [.init(text: "계정 \u{00B7} 개인 기록 \u{00B7} 설정은 바로 삭제돼요")]),
            .init(id: "retain", runs: [
                .init(text: "근무기록 \u{00B7} 급여대장 \u{00B7} 근로계약서처럼 법정 보존 대상인 기록은 "),
                .init(text: "3년간 분리 보관", isBold: true),
                .init(text: " 후 파기돼요"),
            ]),
            .init(id: "cancel", runs: [.init(text: "진행 중인 요청과 예약된 알림은 모두 취소돼요")]),
            .init(id: "restore", runs: [.init(text: "30일 안에 같은 번호로 다시 가입하면 계정을 되살릴 수 있어요")]),
        ],
        staffNote: "직원으로 소속된 사업장이 있다면 탈퇴 시 각 사장님께 퇴사 처리 요청이 함께 전달돼요.",
        withdrawTitle: "소유권 이전 후 탈퇴할 수 있어요"
    )

    /// 정리할 사업장이 없을 때. 버튼 글자는 원문에 없어 임시값(서버 값으로 대체)
    static let cleared = WithdrawState(
        workplaces: [],
        consequencesTitle: sample.consequencesTitle,
        consequences: sample.consequences,
        staffNote: sample.staffNote,
        withdrawTitle: "탈퇴하기"
    )
}
