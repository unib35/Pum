// UI-IOS-1ar · REQ-105 — 사장님 홈 · 할 일 0건: 오늘 근무 4명(근무 중 + 예정)과 인건비
// 비율 · 문구는 화면이 아니라 여기서 만든다(테스트 대상). 시각 문구는 1aq의 OwnerHomeFormat을 재사용한다.
import Foundation

nonisolated struct OwnerHomeClearState: Equatable, Sendable {
    /// 지금 근무 중인 사람(진행 막대 있음)
    struct OnDuty: Identifiable, Equatable, Sendable {
        let id: Int
        let name: String
        let colorIndex: Int
        let clockInMinute: Int
        let plannedEndMinute: Int

        /// 출근 ~ 예정 퇴근 구간에서 지금까지 지난 비율(0–1)
        func progress(now: Int) -> Double {
            let total = plannedEndMinute - clockInMinute
            guard total > 0 else { return 0 }
            return min(1, max(0, Double(now - clockInMinute) / Double(total)))
        }

        var detail: String {
            "\(OwnerHomeFormat.clock(clockInMinute)) 출근 · \(OwnerHomeFormat.clock(plannedEndMinute)) 퇴근 예정"
        }
    }

    /// 아직 출근 전인 예정자(막대 없음)
    struct Scheduled: Identifiable, Equatable, Sendable {
        let id: Int
        let name: String
        let colorIndex: Int
        let startMinute: Int
        let endMinute: Int

        var detail: String { "\(OwnerHomeFormat.clock(startMinute)) – \(OwnerHomeFormat.clock(endMinute)) 예정" }
    }

    let workplaceName: String
    let workplaceInitial: String
    let dateText: String
    /// 접힌 할 일 줄의 둘째 줄(예: 「마지막 처리 12:40 · 김하늘 연장 인정」)
    let lastHandledText: String
    let working: [OnDuty]
    let scheduled: [Scheduled]
    /// 지금 시각(하루 안의 분) — 화면이 주입한다
    let nowMinute: Int
    let staffCount: Int
    let monthNumber: Int
    let expectedPay: Int
    let confirmedPay: Int

    var todayCount: Int { working.count + scheduled.count }
    var todayTitle: String { "오늘 근무 \(todayCount)명" }
    var nowSummary: String { "지금 \(working.count)명 · \(OwnerHomeFormat.clock(nowMinute))" }
    var remainingPay: Int { max(0, expectedPay - confirmedPay) }
    var confirmedRatio: Double {
        guard expectedPay > 0 else { return 0 }
        return min(1, max(0, Double(confirmedPay) / Double(expectedPay)))
    }
    var payrollTitle: String { "\(monthNumber)월 예상 인건비" }
}

extension OwnerHomeClearState {
    /// 디자인 1ar 예시 값(가짜 데이터)
    static let sample = OwnerHomeClearState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        dateText: "10월 3일 토",
        lastHandledText: "마지막 처리 12:40 · 김하늘 연장 인정",
        working: [
            .init(id: 1, name: "최유나", colorIndex: 2, clockInMinute: 8 * 60 + 55, plannedEndMinute: 15 * 60),
            .init(id: 2, name: "박서준", colorIndex: 3, clockInMinute: 9 * 60 + 3, plannedEndMinute: 15 * 60),
        ],
        scheduled: [
            .init(id: 3, name: "이종민", colorIndex: 0, startMinute: 17 * 60, endMinute: 22 * 60),
            .init(id: 4, name: "김하늘", colorIndex: 1, startMinute: 17 * 60, endMinute: 22 * 60),
        ],
        nowMinute: 13 * 60 + 20,
        staffCount: 4,
        monthNumber: 10,
        expectedPay: 4_210_000,
        confirmedPay: 2_680_000
    )
}
