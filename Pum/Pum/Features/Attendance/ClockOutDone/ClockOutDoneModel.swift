// UI-IOS-1f · REQ-024 · REQ-026 · REQ-006 — 퇴근 완료: 근무기록 생성 결과(예정 vs 실제) 데이터
// 인정 근무 · 기본급은 서버(급여 엔진)가 계산해 준 저장 값 — 화면에서 계산하지 않는다(AGENTS.md · REQ-071).
// 실제 체류 · 조기 출근 · 연장은 시각 차이를 보여 주는 표시용 값이라 모델에서 계산한다.
import Foundation

nonisolated struct ClockOutDoneRecord: Equatable, Sendable {
    var dateTitle: String
    var workplaceName: String
    var hourlyWage: Int
    /// 하루 안의 분
    var plannedStart: Int, plannedEnd: Int
    var actualStart: Int, actualEnd: Int
    var breakStart: Int, breakMinutes: Int
    /// 엔진이 계산한 인정 근무(분) · 기본급(정수 원)
    var recognizedMinutes: Int
    var basePay: Int
    /// 사업장 정책: 자동 인정 기준(±분, REQ-026)
    var autoApproveMinutes: Int

    var headline: String { "\(HomeFormat.clock(actualEnd)) 퇴근했어요" }
    var subtitle: String { "\(dateTitle) \u{00B7} \(workplaceName)" }
    var plannedRange: String { PumFormat.timeRange(HomeFormat.clock(plannedStart), HomeFormat.clock(plannedEnd)) }
    var actualRange: String { PumFormat.timeRange(HomeFormat.clock(actualStart), HomeFormat.clock(actualEnd)) }

    /// 실제 체류 = 실제 끝 − 실제 시작(휴게 포함)
    var stayMinutes: Int { actualEnd - actualStart }
    /// 조기 출근 = 예정 시작 − 실제 시작(늦었으면 0)
    var earlyMinutes: Int { max(0, plannedStart - actualStart) }
    /// 연장 = 실제 끝 − 예정 끝(일찍 끝났으면 0)
    var overtimeMinutes: Int { max(0, actualEnd - plannedEnd) }
    /// 자동 인정 기준(±분) 안인지 — 시작 · 끝 차이가 모두 기준 이하
    var isWithinAutoApprove: Bool {
        abs(actualStart - plannedStart) <= autoApproveMinutes && abs(actualEnd - plannedEnd) <= autoApproveMinutes
    }

    var breakText: String { HomeFormat.hours(breakMinutes) }
    var stayText: String { HomeFormat.hours(stayMinutes) }
    var recognizedText: String { HomeFormat.hours(recognizedMinutes) }
    var basePayText: String { PumFormat.amount(basePay) + "원" }
    var wageText: String { " \u{00B7} 시급 \(PumFormat.amount(hourlyWage))원" }

    /// 기준 안일 때만 확정 안내(디자인 1f). 기준 밖 화면은 디자인에 없어 안내를 띄우지 않는다(README 누락 기록).
    var confirmNotice: String? {
        guard isWithinAutoApprove else { return nil }
        var parts: [String] = []
        if earlyMinutes > 0 { parts.append("조기 출근 \(earlyMinutes)분") }
        if overtimeMinutes > 0 { parts.append("연장 \(overtimeMinutes)분") }
        let policy = "사업장 정책(\u{00B1}\(autoApproveMinutes)분 자동 인정)에 따라 바로 확정됐어요. 기록이 다르다면 상세에서 수정 요청할 수 있어요."
        // 예정과 똑같이 근무했으면 차이 문구 없이 정책 문장만
        return parts.isEmpty ? "오늘 기록은 " + policy : parts.joined(separator: "과 ") + "은 " + policy
    }

    var timelineLabel: String {
        "예정 \(HomeFormat.clock(plannedStart))–\(HomeFormat.clock(plannedEnd)), 실제 \(HomeFormat.clock(actualStart))–\(HomeFormat.clock(actualEnd)), 휴게 \(breakMinutes)분"
    }

    /// 디자인 1f 예시 값(가짜 데이터)
    static let sample = ClockOutDoneRecord(
        dateTitle: "10월 3일 토요일", workplaceName: "종민김밥 본점", hourlyWage: 12_000,
        plannedStart: 17 * 60, plannedEnd: 22 * 60,
        actualStart: 16 * 60 + 58, actualEnd: 22 * 60 + 31,
        breakStart: 19 * 60 + 30, breakMinutes: 30,
        recognizedMinutes: 303, basePay: 60_600, // 디자인 1f 값(엔진 결과 예시)
        autoApproveMinutes: 45
    )
}
