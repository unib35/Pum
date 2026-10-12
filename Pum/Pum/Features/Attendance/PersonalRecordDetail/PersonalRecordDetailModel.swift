// UI-IOS-2g · REQ-005 · REQ-006 · DEC-005 — 개인 기록 상세: 본인이 입력한 기록, 자유 수정
// 인정 시간 · 예상 급여는 화면에서 계산하지 않는다 — 엔진(서버)이 계산해 넘긴 값을, 어떤 조건으로 계산했는지와 함께 받아
// 지금 조건과 같을 때만 보인다. 출근 · 퇴근 · 휴게를 바꾸면 옛 값은 숨긴다(새 값은 서버 재계산 후 — 연결 후속).
import Foundation

nonisolated enum PersonalRecordBreak: CaseIterable, Sendable {
    case none, thirty, sixty

    var title: String {
        switch self {
        case .none: "없음"
        case .thirty: "30분"
        case .sixty: "1시간"
        }
    }
    var minutes: Int {
        switch self {
        case .none: 0
        case .thirty: 30
        case .sixty: 60
        }
    }
}

nonisolated enum PersonalRecordField: Sendable { case start, end }

nonisolated struct PersonalRecordDetailState: Equatable, Sendable {
    /// 시간 칸 조절(접근성 증가·감소) 한 번에 움직이는 분 — 디자인 없음
    static let stepMinutes = 10
    static let title = "근무 상세"
    static let tagNote = "본인이 입력한 기록이에요"
    static let notice = "개인 기록은 참고용이에요. 사업장에 초대되면 그 이후 근무는 출퇴근 기록으로 자동 생성되고, 이 기록은 그대로 내 기록으로 남아요."

    /// 어떤 조건으로 계산했는지 — 출근 · 퇴근 · 휴게(분)와 시급(원)
    struct Basis: Equatable, Sendable {
        var startMinute: Int
        var endMinute: Int
        var breakMinutes: Int
        var hourlyWage: Int
    }

    /// 엔진이 계산해 넘긴 인정 시간(분) · 예상 급여(원, 정수)와 그 조건
    struct Calc: Equatable, Sendable {
        var basis: Basis
        var recognizedMinutes: Int
        var estimatedPay: Int
    }

    /// 「10월 2일 금요일」 — 날짜 문구는 모델 값
    var dateText: String
    var workplace: String
    /// 하루 중 분(17:02 = 1022)
    var startMinute: Int
    var endMinute: Int
    var breakOption: PersonalRecordBreak
    /// 내 조건 시급(원, 정수)
    var hourlyWage: Int
    var calc: Calc?
    var memo: String
    /// 저장 처리 중(중복 전송 잠금)
    var isSaving = false

    /// 디자인 원문: 10월 2일 금요일 · 종민김밥 · 17:02–22:31 · 휴게 30분 · 12,000원 · 인정 4시간 59분 · 예상 59,800원
    static let sample: PersonalRecordDetailState = {
        var s = PersonalRecordDetailState(
            dateText: "10월 2일 금요일", workplace: "종민김밥",
            startMinute: 17 * 60 + 2, endMinute: 22 * 60 + 31, breakOption: .thirty, hourlyWage: 12_000,
            calc: nil, memo: "마감 정리 30분 더 함. 사장님이 다음 달에 정산해 준다고 하심.")
        s.calc = Calc(basis: s.basis, recognizedMinutes: 299, estimatedPay: 59_800)
        return s
    }()

    var basis: Basis {
        Basis(startMinute: startMinute, endMinute: endMinute, breakMinutes: breakOption.minutes, hourlyWage: hourlyWage)
    }

    /// 지금 조건으로 계산된 값일 때만 — 아니면 nil(옛 값 숨김)
    var visibleCalc: Calc? { calc.flatMap { $0.basis == basis ? $0 : nil } }

    var subtitle: String { "\(workplace) · \(Self.tagNote)" }
    var startText: String { Self.clock(startMinute) }
    var endText: String { Self.clock(endMinute) }
    var wageText: String { "\(PumFormat.amount(hourlyWage))원" }
    var recognizedText: String? { visibleCalc.map { PumFormat.duration(minutes: $0.recognizedMinutes) } }
    var payText: String? { visibleCalc.map { "\(PumFormat.amount($0.estimatedPay))원" } }

    static func clock(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    func minute(_ field: PersonalRecordField) -> Int { field == .start ? startMinute : endMinute }
    func timeText(_ field: PersonalRecordField) -> String { field == .start ? startText : endText }

    func timeAccessibility(_ field: PersonalRecordField) -> String {
        let m = ((minute(field) % 1440) + 1440) % 1440
        return "\(field == .start ? "출근" : "퇴근") \(m / 60)시 \(m % 60)분"
    }

    /// 하루(24시간) 안에서 돌려 가며 분을 옮긴다
    mutating func step(_ field: PersonalRecordField, by delta: Int) {
        let next = ((minute(field) + delta) % 1440 + 1440) % 1440
        if field == .start { startMinute = next } else { endMinute = next }
    }

    /// C13 시트 설정 — 분 단위(원문 17:02 · 22:31)라 1분 간격. 제목은 2g 화면의 칸 이름
    static let pickerIntervalMinutes = 1
    static func pickerTitle(_ field: PersonalRecordField) -> String { field == .start ? "출근" : "퇴근" }
    /// 시트 시간 행 이름 — 열기 전 기록(1i의 「기록 22:00」과 같은 방식)
    func pickerRowLabel(_ field: PersonalRecordField) -> String { "기록 \(timeText(field))" }

    /// C13 시트에서 고른 시각 반영(순수). 하루 안으로 붙인다. 값이 바뀌면 basis가 달라져 옛 인정 시간 · 예상 급여는 숨는다.
    func applying(picked minutes: Int, for field: PersonalRecordField) -> PersonalRecordDetailState {
        var s = self
        let next = min(max(minutes, 0), 24 * 60 - 1)
        if field == .start { s.startMinute = next } else { s.endMinute = next }
        return s
    }

    mutating func setBreak(_ option: PersonalRecordBreak) { breakOption = option }

    /// 저장은 한 번만 — 처리 중이면 false
    mutating func beginSave() -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        return true
    }
    mutating func endSave() { isSaving = false }
}
