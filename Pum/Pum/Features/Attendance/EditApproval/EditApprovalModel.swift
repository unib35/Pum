// UI-IOS-1s · REQ-006 · REQ-027 · REQ-042 · DEC-005 — 수정 요청 승인(사장님) 데이터
// 사업장 확인 기록은 직원이 수정 요청 → 사업주가 승인해야 바뀐다. 승인 전까지는 기존 기록 그대로(REQ-042).
// 인정 근무 · 기본급 변화는 서버(급여 엔진)가 준 값 그대로 — 화면에서 계산하지 않는다.
import Foundation

/// 변경 이력 한 단계
nonisolated struct ApprovalHistoryStep: Identifiable, Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case done, current, pending

        /// VoiceOver 앞말
        var spokenText: String {
            switch self {
            case .done: "완료"
            case .current: "진행"
            case .pending: "대기"
            }
        }
    }

    let id: Int
    var status: Status
    var title: String
    var detail: String

    /// 「·」는 낭독에서 쉼표로. 제목에 이미 「대기 중」이 있으면 상태 접두어를 반복하지 않는다
    var accessibilityText: String {
        let spokenTitle = title.replacingOccurrences(of: " \u{00B7} ", with: ", ")
        let lead = title.contains(status.spokenText) ? "" : "\(status.spokenText), "
        return lead + spokenTitle + ", " + detail.replacingOccurrences(of: " \u{00B7} ", with: ", ")
    }
}

/// 「인정 근무」「기본급」 변화 한 칸 — 앞 값 → 뒤 값
nonisolated struct ApprovalChange: Equatable, Sendable {
    var label: String
    /// 「4시간 30분 → 」처럼 화살표까지
    var fromText: String
    var toText: String
    var spokenFrom: String
    var spokenTo: String

    var accessibilityText: String { "\(label), \(spokenFrom)에서 \(spokenTo)으로" }
}

nonisolated struct EditApprovalState: Equatable, Sendable {
    var employeeName: String
    /// 아바타 색 고정 키
    var colorIndex: Int
    var month: Int
    var day: Int
    /// 「수」 한 글자
    var weekday: String
    var workplaceName: String
    var hourlyWage: Int
    /// 하루 안의 분
    var recordedEnd: Int
    var requestedEnd: Int
    var message: String
    /// 서버 값: 인정 근무 문구(예: 「4시간 30분」「5시간」) · 기본급(원)
    var recognizedBefore: String
    var recognizedAfter: String
    var payBefore: Int
    var payAfter: Int
    var history: [ApprovalHistoryStep]

    static let screenTitle = "수정 요청"
    static let reviewBadgeText = "검토 중"
    static let fieldLabel = "퇴근시간"
    static let recordedLabel = "기록됨"
    static let requestedLabel = "요청"
    static let recognizedLabel = "인정 근무"
    static let payLabel = "기본급"
    static let historyTitle = "변경 이력"
    static let directEditText = "다른 시간으로 직접 수정"
    static let rejectText = "거절"
    static let arrowText = " \u{2192} "

    var nameInitial: String { PumAvatar.initial(for: employeeName) }
    var recordedEndText: String { HomeFormat.clock(recordedEnd) }
    var requestedEndText: String { HomeFormat.clock(requestedEnd) }

    var dateText: String { "\(month)월 \(day)일 \(weekday)" }
    var subtitleText: String { "\(dateText) \u{00B7} \(workplaceName) \u{00B7} 시급 \(PumFormat.amount(hourlyWage))원" }
    var personAccessibilityText: String { "\(employeeName), \(subtitleText), \(Self.reviewBadgeText)" }

    var timeAccessibilityText: String {
        // 승인 전에는 기존 기록이 유효(REQ-042) — 바뀐 것처럼 들리지 않게 「승인 전」을 붙인다
        "\(Self.fieldLabel), \(Self.recordedLabel) \(recordedEndText), \(Self.requestedLabel) \(requestedEndText), 승인 전"
    }

    /// 하단 승인 버튼 — 요청 시각에서 만든다
    var approveText: String { "승인 \u{00B7} \(requestedEndText)으로 확정" }

    var recognizedChange: ApprovalChange {
        ApprovalChange(label: Self.recognizedLabel, fromText: recognizedBefore + Self.arrowText, toText: recognizedAfter,
                       spokenFrom: recognizedBefore, spokenTo: recognizedAfter)
    }

    var payChange: ApprovalChange {
        ApprovalChange(label: Self.payLabel, fromText: PumFormat.amount(payBefore) + Self.arrowText,
                       toText: PumFormat.amount(payAfter) + "원",
                       spokenFrom: PumFormat.amount(payBefore) + "원", spokenTo: PumFormat.amount(payAfter) + "원")
    }

    var messageAccessibilityText: String { "직원 메시지, \(message)" }

    /// 승인 대기 단계 보조 문구(요청 시각에서)
    static func pendingDetail(requestedEnd: String) -> String { "승인하면 근무기록이 \(requestedEnd)으로 확정돼요" }

    /// 디자인 1s 예시(가짜 값)
    static let sample = EditApprovalState(
        employeeName: "김하늘", colorIndex: 1, month: 9, day: 30, weekday: "수",
        workplaceName: "종민김밥 본점", hourlyWage: 12_000,
        recordedEnd: 22 * 60, requestedEnd: 22 * 60 + 30,
        message: "\"퇴근 버튼을 먼저 눌렀지만 사장님 요청으로 30분 추가 근무했습니다. 마감 정리 도와드렸어요.\"",
        recognizedBefore: "4시간 30분", recognizedAfter: "5시간", payBefore: 54_000, payAfter: 60_000,
        history: [
            ApprovalHistoryStep(id: 1, status: .done, title: "퇴근 기록 생성 \u{00B7} 22:00",
                                detail: "09/30 22:01 \u{00B7} 매장 QR \u{00B7} 시스템"),
            ApprovalHistoryStep(id: 2, status: .current, title: "직원 수정 요청 \u{00B7} 22:00 \u{2192} 22:30",
                                detail: "10/01 09:12 \u{00B7} 김하늘"),
            ApprovalHistoryStep(id: 3, status: .pending, title: "사업주 승인 \u{00B7} 대기 중",
                                detail: pendingDetail(requestedEnd: "22:30")),
        ]
    )
}
