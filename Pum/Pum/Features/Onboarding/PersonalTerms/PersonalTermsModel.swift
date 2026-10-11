// UI-IOS-2e · REQ-005 — 개인 근로조건(급여 계산기 설정) 상태
// 돈은 정수(원). 예상 월급은 화면에서 계산하지 않고 엔진(서버) 값을 받아 표시만 한다.
import Foundation

struct PersonalTermsState: Equatable {
    enum PayType: String, CaseIterable, Equatable {
        case hourly = "시급", daily = "일급", monthly = "월급"
        /// 알약 · 금액 행 이름(문구는 알약 이름 그대로)
        var title: String { rawValue }
    }

    /// 요일 칩 순서: 월~일. 값은 월=1 … 일=7
    static let weekdays: [(id: Int, short: String, long: String)] = [
        (1, "월", "월요일"), (2, "화", "화요일"), (3, "수", "수요일"), (4, "목", "목요일"),
        (5, "금", "금요일"), (6, "토", "토요일"), (7, "일", "일요일"),
    ]
    static let sunday = 7
    /// 금액 입력 최대 자릿수(정수 오버플로 방지용 안전 한도)
    static let maxAmountDigits = 9

    var workplace: String = ""
    var payType: PayType = .hourly
    /// 원 단위 정수
    var amount: Int = 0
    var days: Set<Int> = []
    /// 하루 중 분(17:00 = 1020)
    var startMinute: Int = 17 * 60
    var endMinute: Int = 22 * 60
    var breakMinutes: Int = 30
    /// 매월 N일
    var payday: Int = 10
    /// 엔진(서버)이 계산해 넘긴 한 달 예상(원). 없으면 상자를 숨긴다.
    var estimatedMonthly: Int?

    /// 디자인 원문: 종민김밥 · 시급 12,000원 · 월수금 · 17:00–22:00 · 휴게 30분 · 매월 10일 · 약 1,184,000원
    static let sample = PersonalTermsState(
        workplace: "종민김밥", payType: .hourly, amount: 12_000, days: [1, 3, 5],
        startMinute: 17 * 60, endMinute: 22 * 60, breakMinutes: 30, payday: 10, estimatedMonthly: 1_184_000)

    /// 실제 진입: 비어 있는 기본값(금액 0 · 요일 없음)
    static let entry = PersonalTermsState()

    /// 「시작하기」 활성 조건(비활성 이유 문구는 디자인 없음 — 충돌 #30)
    var canStart: Bool { amount > 0 && !days.isEmpty }

    /// 숫자만 · 최대 9자리 정수로 다듬는다(쉼표 · 원 · 붙여넣기 포함)
    static func sanitizedAmount(_ raw: String) -> Int {
        Int(String(raw.filter { $0.isASCII && $0.isNumber }.prefix(maxAmountDigits))) ?? 0
    }

    func isSelected(_ day: Int) -> Bool { days.contains(day) }

    mutating func toggleDay(_ day: Int) {
        if days.contains(day) { days.remove(day) } else { days.insert(day) }
    }

    var amountText: String { amount > 0 ? PumFormat.amount(amount) : "" }
    var amountAccessibilityValue: String { amount > 0 ? "\(PumFormat.amount(amount))원" : "입력 안 됨" }

    static func clock(_ minute: Int) -> String {
        String(format: "%02d:%02d", (minute / 60) % 24, minute % 60)
    }
    var timeRangeText: String { PumFormat.timeRange(Self.clock(startMinute), Self.clock(endMinute)) }
    var breakText: String { "\(breakMinutes)분" }
    var paydayText: String { "매월 \(payday)일" }
    var estimateText: String? { estimatedMonthly.map { "약 \(PumFormat.amount($0))원" } }
}
