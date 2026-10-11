// UI-IOS-1h · REQ-006 · REQ-022 · REQ-071 — 근무 상세(확정) 화면 데이터와 계산 근거
// 사업장 확인 기록이라 화면에서 직접 고치지 않는다 — 「수정 요청」 경로만(REQ-006).
// 인정 근무 · 기본급은 서버(급여 엔진)가 계산해 준 값을 그대로 보여 준다 — 화면에서 계산하지 않는다(AGENTS.md · REQ-071).
import Foundation

nonisolated struct WorkDetailRecord: Equatable, Sendable {
    struct HistoryItem: Equatable, Sendable, Identifiable {
        let id: Int          // 같은 분에 여러 건이어도 겹치지 않게 순번
        let stamp: String   // 「10/03 16:58」
        let text: String
    }

    var dateTitle: String
    var statusText: String
    var workplaceName: String
    var hourlyWage: Int
    /// 하루 안의 분
    var plannedStart: Int, plannedEnd: Int
    var actualStart: Int, actualEnd: Int
    var breakStart: Int, breakMinutes: Int
    /// 엔진이 계산한 인정 근무(분) · 해당 근무 기본급(정수 원) — 계산 근거(Trace)는 서버에 있다
    var recognizedMinutes: Int
    var basePay: Int
    var history: [HistoryItem]

    var subtitle: String { "\(workplaceName) · 시급 \(PumFormat.amount(hourlyWage))원" }
    var plannedRange: String { range(plannedStart, plannedEnd) }
    var actualRange: String { range(actualStart, actualEnd) }
    /// F4: 「N시간 NN분」, 딱 떨어지면 「N시간」
    var breakText: String { HomeFormat.hours(breakMinutes) }
    var recognizedText: String { HomeFormat.hours(recognizedMinutes) }
    var basePayText: String { PumFormat.amount(basePay) + "원" }

    var timelineLabel: String {
        "예정 \(HomeFormat.clock(plannedStart))–\(HomeFormat.clock(plannedEnd)), 실제 \(HomeFormat.clock(actualStart))–\(HomeFormat.clock(actualEnd)), 휴게 \(breakMinutes)분"
    }

    private func range(_ s: Int, _ e: Int) -> String {
        PumFormat.timeRange(HomeFormat.clock(s), HomeFormat.clock(e))
    }

    /// 디자인 1h 예시 값(가짜 데이터)
    static let sample = WorkDetailRecord(
        dateTitle: "10월 3일 토요일", statusText: "확정",
        workplaceName: "종민김밥 본점", hourlyWage: 12_000,
        plannedStart: 17 * 60, plannedEnd: 22 * 60,
        actualStart: 16 * 60 + 58, actualEnd: 22 * 60 + 31,
        breakStart: 19 * 60 + 30, breakMinutes: 30,
        recognizedMinutes: 303, basePay: 60_600, // 디자인 1h 값(엔진 결과 예시)
        history: [
            .init(id: 0, stamp: "10/03 16:58", text: "출근 기록 생성 · 매장 QR"),
            .init(id: 1, stamp: "10/03 22:31", text: "퇴근 기록 생성 · 정책에 따라 자동 확정"),
        ]
    )
}

/// 타임라인 가로축(16:00–23:00)과 시각 → 0–1 위치
nonisolated struct WorkTimelineAxis: Equatable, Sendable {
    var startMinute = 16 * 60
    var endMinute = 23 * 60

    var tickCount: Int { (endMinute - startMinute) / 60 + 1 }
    var tickLabels: [String] { (0..<tickCount).map { HomeFormat.clock(startMinute + $0 * 60) } }

    /// 축 밖은 0–1로 자른다
    func position(_ minute: Int) -> Double {
        let total = Double(max(1, endMinute - startMinute))
        return min(1, max(0, Double(minute - startMinute) / total))
    }

    /// (시작 위치, 길이 비율)
    func span(_ start: Int, _ end: Int) -> (start: Double, length: Double) {
        let s = position(start), e = position(end)
        return (s, max(0, e - s))
    }
}
