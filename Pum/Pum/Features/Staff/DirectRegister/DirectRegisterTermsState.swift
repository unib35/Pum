// UI-IOS-20c · REQ-007 · DEC-001 — 직접 등록 2/3 · 근로조건 (초대 직원과 같은 항목, 이걸로 근무기록을 미리 채움)
// 시급 · 요일은 화면 초안. 하루 시간 · 급여일 · 공제 · 계좌 표시는 서버 · 호출자 문자열(화면 계산 없음).
import Foundation

/// 시급 · 근무 요일 화면 초안
nonisolated struct DirectRegisterTermsDraft: Equatable, Sendable {
    var hourlyWage: Int
    /// 1=월 … 7=일
    var weekdays: Set<Int>
}

/// 다음 단계로 넘길 값
nonisolated struct DirectRegisterTermsValue: Equatable, Sendable {
    let hourlyWage: Int
    let weekdays: [Int]
}

nonisolated struct DirectRegisterTermsState: Equatable, Sendable {
    static let backTitle = "기본 정보"
    static let title = "근로조건"
    static let currentStep = 2
    static let wageTitle = "시급"
    static let workTitle = "근무일 · 시간"
    static let paydayTitle = "급여일"
    static let deductionTitle = "공제"
    static let accountTitle = "계좌"
    static let accountHint = "지급할 때 복사용 · 나중에 넣어도 돼요"
    static let nextTitle = "다음"
    /// 19b와 같은 문구 · 원문 없음
    static let belowMinimumHint = "최저임금 이상이어야 해요"
    /// 시급 숫자 최대 자릿수(과한 입력 방지)
    static let maxWageDigits = 9

    var hourlyWage: Int
    var weekdays: Set<Int>
    /// 서버 최저시급(원). 원문 10,320
    let minimumWage: Int
    /// 원문 「2026 최저 10,320원」 — 서버 값
    let minimumWageText: String
    /// 원문 「17:00 – 22:00」
    let timeRangeText: String
    /// 원문 「휴게 30분 · 하루 4시간 30분」 — 서버 값
    let breakAndDurationText: String
    /// 원문 「매월 10일」
    let paydayText: String
    /// 원문 「3.3%」
    let deductionText: String
    /// 원문 「추가」(계좌가 있으면 호출자가 마스킹 문자열을 넣는다)
    let accountValueText: String

    var initialDraft: DirectRegisterTermsDraft { .init(hourlyWage: hourlyWage, weekdays: weekdays) }

    static func won(_ amount: Int) -> String { PumFormat.amount(amount) + "원" }

    /// 숫자만 받는다. 비면 0
    static func wage(fromInput s: String) -> Int {
        Int(String(s.filter { $0.isASCII && $0.isNumber }.prefix(maxWageDigits))) ?? 0
    }

    func isBelowMinimum(_ draft: DirectRegisterTermsDraft) -> Bool { draft.hourlyWage < minimumWage }

    func canProceed(_ draft: DirectRegisterTermsDraft) -> Bool {
        !isBelowMinimum(draft) && !draft.weekdays.isEmpty
    }

    func value(_ draft: DirectRegisterTermsDraft) -> DirectRegisterTermsValue {
        .init(hourlyWage: draft.hourlyWage, weekdays: draft.weekdays.sorted())
    }

    // MARK: 읽기 문구

    static var stepReadout: String { DirectRegisterStepBar.readout(current: currentStep) }
    func timeReadout() -> String { "\(timeRangeText), \(breakAndDurationText)" }
    func accountReadout() -> String { "\(Self.accountTitle), \(Self.accountHint), \(accountValueText)" }
    func paydayReadout() -> String { "\(Self.paydayTitle), \(paydayText)" }
    func deductionReadout() -> String { "\(Self.deductionTitle), \(deductionText)" }
    func wageReadout() -> String { "\(Self.wageTitle), \(minimumWageText)" }

    // MARK: 예시

    static let sample = DirectRegisterTermsState(
        hourlyWage: 10_320, weekdays: [1, 3, 5], minimumWage: 10_320,
        minimumWageText: "2026 최저 10,320원",
        timeRangeText: PumFormat.timeRange("17:00", "22:00"),
        breakAndDurationText: "휴게 30분 · 하루 4시간 30분",
        paydayText: "매월 10일", deductionText: "3.3%", accountValueText: "추가")
}
