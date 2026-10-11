// UI-IOS-1aq · REQ-105 · REQ-027 — 사장님 홈: 결정 → 현장 → 돈 순서 고정. 화면 데이터와 문구 · 비율 계산
// 비율 · 「N분 지남」 · 「연장 1시간 2분」 문구는 화면이 아니라 여기서 만든다(테스트 대상).
import Foundation

nonisolated struct OwnerHomeState: Equatable, Sendable {
    /// 한 번에 끝나는 결정 하나(홈에서 바로 처리)
    struct Decision: Identifiable, Equatable, Sendable {
        enum Kind: Equatable, Sendable {
            /// 연장 근무 — 인정 버튼
            case overtime(extraMinutes: Int)
            /// 퇴근 기록 없음 — 처리 버튼
            case missingClockOut
        }
        let id: Int
        let name: String
        let colorIndex: Int
        let kind: Kind
        /// 둘째 줄(예: 「어제 예정 22:00 → 23:02 퇴근」)
        let detail: String

        var title: String {
            switch kind {
            case .overtime(let m): "\(name) · \(OwnerHomeFormat.overtime(minutes: m))"
            case .missingClockOut: "\(name) · 퇴근 기록 없음"
            }
        }
        var actionTitle: String {
            switch kind {
            case .overtime: "인정"
            case .missingClockOut: "처리"
            }
        }
    }

    /// 지금 근무 중인 사람
    struct OnDuty: Identifiable, Equatable, Sendable {
        let id: Int
        let name: String
        let colorIndex: Int
        let clockInMinute: Int
        let plannedEndMinute: Int

        /// 예정 퇴근을 지난 분(지나지 않았으면 0)
        func overdueMinutes(now: Int) -> Int { max(0, now - plannedEndMinute) }
        func isOverdue(now: Int) -> Bool { overdueMinutes(now: now) > 0 }

        /// 출근 ~ 예정 퇴근 구간에서 지금까지 지난 비율(0–1)
        func progress(now: Int) -> Double {
            let total = plannedEndMinute - clockInMinute
            guard total > 0 else { return 0 }
            return min(1, max(0, Double(now - clockInMinute) / Double(total)))
        }

        func detail(now: Int) -> String {
            isOverdue(now: now)
                ? "\(OwnerHomeFormat.clock(clockInMinute)) 출근 · 예정 \(OwnerHomeFormat.clock(plannedEndMinute))"
                : "\(OwnerHomeFormat.clock(clockInMinute)) 출근 · \(OwnerHomeFormat.clock(plannedEndMinute)) 퇴근 예정"
        }
    }

    let workplaceName: String
    let workplaceInitial: String
    let hasUnreadNotification: Bool
    let dateText: String
    let decisions: [Decision]
    /// 「그 밖에 N건」(지각 · 예정 외 근무 · 수정 요청 · 대타) — 목록 화면으로 이동
    let otherCount: Int
    let otherSummary: String
    let working: [OnDuty]
    /// 지금 시각(하루 안의 분) — 화면이 주입한다
    let nowMinute: Int
    let nextShiftText: String
    let lastClockOutText: String
    /// 탭 바 「근무」 배지
    let workTabBadge: Int
    let staffCount: Int
    let monthNumber: Int
    /// 이번 달 예상 인건비 · 확정 금액(정수 원)
    let expectedPay: Int
    let confirmedPay: Int

    /// 처리할 일 = 홈에서 처리하는 행 + 그 밖에 건수
    var attentionCount: Int { decisions.count + otherCount }
    var remainingPay: Int { max(0, expectedPay - confirmedPay) }
    /// 확정 비율(0–1)
    var confirmedRatio: Double {
        guard expectedPay > 0 else { return 0 }
        return min(1, max(0, Double(confirmedPay) / Double(expectedPay)))
    }
    var payrollTitle: String { "\(monthNumber)월 예상 인건비" }
}

nonisolated enum OwnerHomeFormat {
    /// 1320 → "22:00"
    static func clock(_ minute: Int) -> String {
        String(format: "%02d:%02d", (minute / 60) % 24, minute % 60)
    }

    /// 62 → "연장 1시간 2분", 45 → "연장 45분", 120 → "연장 2시간"
    static func overtime(minutes: Int) -> String { "연장 " + plain(minutes: minutes) }

    /// 40 → "40분 지남", 65 → "1시간 5분 지남"
    static func overdue(minutes: Int) -> String { plain(minutes: minutes) + " 지남" }

    /// 62 → "1시간 2분" (디자인 1az 원문은 분을 두 자리로 맞추지 않는다)
    static func plain(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)분" }
        return m == 0 ? "\(h)시간" : "\(h)시간 \(m)분"
    }

    static func won(_ amount: Int) -> String { PumFormat.amount(amount) + "원" }
}

extension OwnerHomeState {
    /// 디자인 1az 예시 값(가짜 데이터)
    static let sample = OwnerHomeState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        hasUnreadNotification: true,
        dateText: "10월 3일 토",
        decisions: [
            .init(id: 1, name: "김하늘", colorIndex: 1, kind: .overtime(extraMinutes: 62), detail: "어제 예정 22:00 → 23:02 퇴근"),
            .init(id: 2, name: "박서준", colorIndex: 3, kind: .missingClockOut, detail: "어제 09:03 출근 · 예정 15:00"),
        ],
        otherCount: 4,
        otherSummary: "지각 · 예정 외 근무 · 수정 요청 · 대타",
        working: [
            .init(id: 3, name: "최유나", colorIndex: 2, clockInMinute: 8 * 60 + 55, plannedEndMinute: 15 * 60),
            .init(id: 4, name: "이종민", colorIndex: 0, clockInMinute: 14 * 60 + 57, plannedEndMinute: 22 * 60),
        ],
        nowMinute: 15 * 60 + 40,
        nextShiftText: "17:00 출근 예정 · 김하늘",
        lastClockOutText: "퇴근 박서준 15:04",
        workTabBadge: 4,
        staffCount: 4,
        monthNumber: 10,
        expectedPay: 4_210_000,
        confirmedPay: 2_680_000
    )
}
