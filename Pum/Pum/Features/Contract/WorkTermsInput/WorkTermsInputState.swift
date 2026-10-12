// UI-IOS-10a · REQ-008 · REQ-060 — 근로조건 입력(직원×사업장 단위, 서면 명시 항목부터).
// 주 소정근로시간 · 적용 대상 · 최저임금 · 휴게 안내 · 필수 항목 개수 · 미리보기 가능 여부는 서버(엔진) 값 — 화면에서 계산하지 않는다.
// 결과는 계산 조건(basis)과 함께 받고, 지금 입력이 basis와 같을 때만 숫자 · 적용 대상 · 필수 항목 줄을 보인다(8d와 같은 규칙).
// REQ-051: 주휴수당 · 4대보험 문구는 엔진이 준 그대로 — 피하라는 추천 · 강조 문구를 만들지 않는다.
import Foundation

/// 입력값 = 계산 조건. 요일 id는 월 1 … 일 7(C13와 같음). 급여일 · 지급 방법 · 계약 기간은 선택 화면(#192)이 미정이라 글자만 가진다.
nonisolated struct WorkTermsInputs: Equatable, Sendable {
    /// 시급(원, 정수)
    var hourlyWon: Int
    /// 「매월 10일」
    var paydayText: String
    /// 「계좌 이체」
    var payMethodText: String
    /// 「2026.10.6 – 기간 없음」
    var periodText: String
    var weekdays: Set<Int>
    /// 하루 중 분(0 ..< 1440, Asia/Seoul 벽시계)
    var startMinutes: Int
    var endMinutes: Int
    /// 0(없음) · 30 · 60
    var breakMinutes: Int
}

/// 서버(엔진) 결과. 숫자와 문구는 받은 그대로 보여 준다.
nonisolated struct WorkTermsResult: Equatable, Sendable {
    /// 이 결과를 계산한 조건
    var basis: WorkTermsInputs
    /// 주 소정근로시간(분) — 서버 값
    var weeklyMinutes: Int
    /// 「주휴수당 · 4대보험 적용 대상」 — 서버 문구
    var benefitsText: String
    /// 서버가 준 최저임금(원, 정수)
    var minimumWageWon: Int
    /// 「4시간 이상 근무하면 30분 이상」 — 서버 문구
    var breakNotice: String
    /// 필수 기재 항목 입력 개수
    var requiredFilledCount: Int
    /// 필수 항목을 다 입력했는지 — 「계약서 미리보기」 활성 조건
    var canPreview: Bool
}

nonisolated struct WorkTermsInputState: Equatable, Sendable {
    static let title = "근로조건"
    static let stepText = "1/2"
    static let employeeBadge = "계약 전"
    static let wageHeading = "임금"
    static let workHeading = "근무"
    static let weeklyTitle = "주 소정근로시간"
    static let showItemsTitle = "항목 보기"
    static let previewTitle = "계약서 미리보기"
    static let dash = " \u{2013} "

    var employeeName: String
    /// 「종민김밥 본점 · 10월 2일 초대 수락」
    var subtitle: String
    var inputs: WorkTermsInputs
    /// 마지막으로 받은 엔진 결과. 아직 없으면 nil
    var result: WorkTermsResult?

    /// 원문 값(입력 = basis)
    static let sample: WorkTermsInputState = {
        let inputs = WorkTermsInputs(
            hourlyWon: 11_500, paydayText: "매월 10일", payMethodText: "계좌 이체",
            periodText: "2026.10.6\(dash)기간 없음", weekdays: [1, 3, 5, 6],
            startMinutes: 17 * 60, endMinutes: 22 * 60, breakMinutes: 30)
        return WorkTermsInputState(
            employeeName: "김하늘", subtitle: "종민김밥 본점 \u{00B7} 10월 2일 초대 수락", inputs: inputs,
            result: WorkTermsResult(
                basis: inputs, weeklyMinutes: 18 * 60, benefitsText: "주휴수당 \u{00B7} 4대보험 적용 대상",
                minimumWageWon: 10_320, breakNotice: "4시간 이상 근무하면 30분 이상",
                requiredFilledCount: 8, canPreview: true))
    }()

    // MARK: 결과 보임 규칙

    /// 결과가 있고 지금 입력과 계산 조건이 같을 때만 true
    var resultIsCurrent: Bool { result?.basis == inputs }
    /// 숫자 · 적용 대상 · 필수 항목에 쓰는 결과 — 조건이 다르면 nil(숨김)
    var visibleResult: WorkTermsResult? { resultIsCurrent ? result : nil }
    /// 「계약서 미리보기」 활성 — 서버가 준 canPreview이고 조건이 같을 때만
    var canPreview: Bool { visibleResult?.canPreview ?? false }

    // MARK: 입력 문구

    var wageText: String { "\(PumFormat.amount(inputs.hourlyWon))원" }

    var timeText: String {
        PumTimeWheelMath.clockText(inputs.startMinutes) + Self.dash + PumTimeWheelMath.clockText(inputs.endMinutes)
    }

    var timeSpoken: String {
        "\(PumTimeWheelMath.spokenText(inputs.startMinutes))부터 \(PumTimeWheelMath.spokenText(inputs.endMinutes))까지"
    }

    var breakText: String {
        PumTimePickerStyle.breakChoices.first { $0.minutes == inputs.breakMinutes }?.title ?? "\(inputs.breakMinutes)분"
    }

    // MARK: 서버 값 문구

    /// 「최저임금 10,320원 이상」 — 최저임금은 입력과 무관한 기준값이라 마지막 결과를 그대로 쓴다
    var minimumWageText: String? {
        result.map { "최저임금 \(PumFormat.amount($0.minimumWageWon))원 이상" }
    }

    /// 시급이 서버가 준 최저임금보다 낮은가 — 서버 값과 비교만 한다
    var isBelowMinimumWage: Bool {
        guard let min = result?.minimumWageWon else { return false }
        return inputs.hourlyWon < min
    }

    var breakNotice: String? { visibleResult?.breakNotice }

    var weeklyText: String? { visibleResult.map { Self.durationText(minutes: $0.weeklyMinutes) } }
    var benefitsText: String? { visibleResult?.benefitsText }

    var requiredText: String? {
        visibleResult.map { "필수 기재 항목 \($0.requiredFilledCount)개 입력됨" }
    }

    /// 분 → 「18시간」 · 「18시간 30분」 (서버가 준 분을 글자로만 바꾼다)
    static func durationText(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if m == 0 { return "\(h)시간" }
        return h == 0 ? "\(m)분" : "\(h)시간 \(m)분"
    }

    /// VoiceOver — 「시급, 11,500원, 최저임금 10,320원 이상」
    var wageSpoken: String {
        ["시급", wageText, minimumWageText].compactMap { $0 }.joined(separator: ", ")
    }

    // MARK: 요일

    func isWeekdaySelected(_ id: Int) -> Bool { inputs.weekdays.contains(id) }

    mutating func toggleWeekday(_ id: Int) {
        if inputs.weekdays.contains(id) { inputs.weekdays.remove(id) } else { inputs.weekdays.insert(id) }
    }

    // MARK: C13 시트

    var pickerValue: PumTimeRangeValue {
        var v = PumTimeRangeValue()
        v.startMinutes = inputs.startMinutes
        v.endMinutes = inputs.endMinutes
        v.breakMinutes = inputs.breakMinutes
        v.weekdays = inputs.weekdays
        return v
    }

    /// 시트 「완료」 — 시간 · 휴게만 가져온다
    mutating func apply(picked: PumTimeRangeValue) {
        inputs.startMinutes = picked.startMinutes
        inputs.endMinutes = picked.endMinutes
        inputs.breakMinutes = picked.breakMinutes
    }
}
