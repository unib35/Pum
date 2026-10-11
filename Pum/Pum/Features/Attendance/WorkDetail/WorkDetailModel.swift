// UI-IOS-1h · REQ-006 · REQ-022 · REQ-071 — 근무 상세(확정) 화면 데이터와 계산 근거
// 사업장 확인 기록이라 화면에서 직접 고치지 않는다 — 「수정 요청」 경로만(REQ-006).
// 아래 계산은 화면 안내용이다. 실제 급여 계산은 서버(엔진)가 한다.
import Foundation

nonisolated struct WorkDetailRecord: Equatable, Sendable {
    struct HistoryItem: Equatable, Sendable, Identifiable {
        var id: String { stamp }
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
    var history: [HistoryItem]

    /// 인정 근무(분) = 실제 근무 − 휴게
    var recognizedMinutes: Int { max(0, actualEnd - actualStart - breakMinutes) }
    /// 기본급(원) = 시급 × 인정 분 ÷ 60, 정수 원 버림. 안내용 — 실제 계산은 서버
    var basePay: Int { hourlyWage * recognizedMinutes / 60 }

    var subtitle: String { "\(workplaceName) · 시급 \(PumFormat.amount(hourlyWage))원" }
    var plannedRange: String { range(plannedStart, plannedEnd) }
    var actualRange: String { range(actualStart, actualEnd) }
    var breakText: String { PumFormat.duration(minutes: breakMinutes) }
    var recognizedText: String { PumFormat.duration(minutes: recognizedMinutes) }
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
        history: [
            .init(stamp: "10/03 16:58", text: "출근 기록 생성 · 매장 QR"),
            .init(stamp: "10/03 22:31", text: "퇴근 기록 생성 · 정책에 따라 자동 확정"),
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
