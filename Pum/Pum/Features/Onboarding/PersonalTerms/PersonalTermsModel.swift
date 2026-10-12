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
    /// 엔진(서버)이 계산해 넘긴 한 달 예상. 지금 조건으로 계산된 값일 때만 보인다(없으면 상자 숨김).
    var estimate: Estimate?

    /// 예상 월급 계산에 쓰이는 조건(일하는 곳 · 급여일은 금액에 영향 없음)
    struct Basis: Equatable {
        var payType: PayType
        var amount: Int
        var days: Set<Int>
        var startMinute: Int
        var endMinute: Int
        var breakMinutes: Int
    }

    /// 어떤 조건으로 계산했는지와 금액(원) — 조건이 바뀌면 옛 값을 보이지 않게
    struct Estimate: Equatable {
        var basis: Basis
        var amount: Int
    }

    var basis: Basis {
        Basis(payType: payType, amount: amount, days: days,
              startMinute: startMinute, endMinute: endMinute, breakMinutes: breakMinutes)
    }

    /// 디자인 원문: 종민김밥 · 시급 12,000원 · 월수금 · 17:00–22:00 · 휴게 30분 · 매월 10일 · 약 1,184,000원
    static let sample: PersonalTermsState = {
        var s = PersonalTermsState(
            workplace: "종민김밥", payType: .hourly, amount: 12_000, days: [1, 3, 5],
            startMinute: 17 * 60, endMinute: 22 * 60, breakMinutes: 30, payday: 10)
        s.estimate = Estimate(basis: s.basis, amount: 1_184_000)
        return s
    }()

    /// 실제 진입: 비어 있는 기본값(금액 0 · 요일 없음)
    static let entry = PersonalTermsState()

    /// 「시작하기」 활성 조건(비활성 이유 문구는 디자인 없음 — 충돌 #30)
    var canStart: Bool { amount > 0 && !days.isEmpty }

    /// 숫자만 · 최대 9자리 정수로 다듬는다(쉼표 · 원 · 붙여넣기 포함). 소수점 아래는 버린다(「1.5」 → 1).
    static func sanitizedAmount(_ raw: String) -> Int {
        let whole = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        return Int(String(whole.filter { $0.isASCII && $0.isNumber }.prefix(maxAmountDigits))) ?? 0
    }

    /// C13 시트 설정 — 근무 시간(시작 → 끝, 원문 17:00 – 22:00)이라 30분 간격
    static let pickerIntervalMinutes = 30
    static let pickerTitle = "근무 시간"
    /// 시트 휴게 알약과 같은 값(없음 · 30분 · 1시간)
    static let breakChoices = [0, 30, 60]

    /// C13 시트에서 고른 값 반영(순수). 시각은 하루 안으로 붙이고(끝이 시작보다 이르면 다음 날로 넘어간 것), 휴게는 알약 값만 받는다.
    /// 값이 바뀌면 basis가 달라져 옛 엔진 예상은 `estimateText`에서 숨는다.
    func applying(pickedStart start: Int, end: Int, breakMinutes pickedBreak: Int) -> PersonalTermsState {
        var s = self
        s.startMinute = min(max(start, 0), 24 * 60 - 1)
        s.endMinute = min(max(end, 0), 24 * 60 - 1)
        if Self.breakChoices.contains(pickedBreak) { s.breakMinutes = pickedBreak }
        return s
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
    /// 지금 조건으로 계산된 예상만 표시
    var estimateText: String? {
        guard let e = estimate, e.basis == basis else { return nil }
        return "약 \(PumFormat.amount(e.amount))원"
    }
}
