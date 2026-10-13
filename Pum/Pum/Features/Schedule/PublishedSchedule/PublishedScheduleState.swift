// UI-IOS-17e · REQ-050 — 직원 · 스케줄 게시 후: 다음 주 근무 · 예상 급여 · 이번 주 요약
// 시간 · 금액 · 휴일 가산 · 새로 게시 여부는 모두 서버(엔진) 값이다. 화면은 문구로만 바꾸고 계산하지 않는다(DEC-008).
import Foundation

nonisolated struct PublishedShift: Equatable, Identifiable, Sendable {
    let weekday: String          // "월"
    let day: Int                 // 5
    let startText: String        // "17:00"
    let endText: String          // "22:00"
    let paidMinutes: Int         // 서버 인정 근무 분 — 270
    let isHolidayPremium: Bool   // 서버가 정한 휴일 가산

    var id: String { "\(weekday)\(day)" }

    /// 「월 5일」
    var dateText: String { "\(weekday) \(day)일" }

    /// 「17:00 – 22:00」
    var rangeText: String { PumFormat.timeRange(startText, endText) }

    /// 「4.5h」 — 서버가 준 분을 시간 표기로만 바꾼다
    var hoursText: String { PublishedFormat.decimalHours(paidMinutes) }

    /// 「금 9일, 17:00부터 22:00, 휴일 가산, 4.5시간」
    var accessibilityText: String {
        var parts = [dateText + ",", "\(startText)부터 \(endText),"]
        if isHolidayPremium { parts.append("휴일 가산,") }
        parts.append(PublishedFormat.decimalHours(paidMinutes).replacingOccurrences(of: "h", with: "시간"))
        return parts.joined(separator: " ")
    }
}

nonisolated enum PublishedFormat {
    /// 270 → "4.5h", 300 → "5h" (소수 한 자리가 0이면 생략)
    static func decimalHours(_ minutes: Int) -> String {
        let whole = minutes / 60
        let tenths = (minutes % 60) * 10 / 60
        return tenths == 0 ? "\(whole)h" : "\(whole).\(tenths)h"
    }
}

nonisolated struct PublishedScheduleState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    var nextWeekTitle: String            // "다음 주 · 10월 5일 – 11일"
    var isNewlyPublished: Bool           // 「새로 게시」 배지 — 서버 값
    var shifts: [PublishedShift]
    var nextWeekPaidMinutes: Int         // 서버 합계
    var expectedPay: Int                 // 원(정수) — 서버 계산
    var includesHolidayPremium: Bool     // 예상 급여에 휴일 가산 포함
    var thisWeekTitle: String            // "이번 주 · 9월 28일 – 10월 4일"
    var thisWeekDays: Int
    var thisWeekPaidMinutes: Int

    static let newlyPublishedBadge = "새로 게시"
    static let holidayBadge = "휴일 가산"
    static let coverTitle = "대타 요청 보내기"
    static let coverCaption = "근무를 고르면 동료에게 요청이 가요"
    static let screenTitle = "내 스케줄"

    var workDaysText: String { "\(shifts.count)일" }
    var nextWeekHoursText: String { HomeFormat.hours(nextWeekPaidMinutes) }
    var expectedPayText: String { "\(PumFormat.amount(expectedPay))원" }
    var payCaption: String? { includesHolidayPremium ? "휴일 가산 포함" : nil }
    /// 「3일 · 14시간 30분」
    var thisWeekSummary: String { "\(thisWeekDays)일 · \(HomeFormat.hours(thisWeekPaidMinutes))" }

    var hoursAccessibility: String { "다음 주 근무, \(nextWeekHoursText), \(workDaysText)" }
    var payAccessibility: String { "예상 급여, \(expectedPayText)" + (payCaption.map { ", \($0)" } ?? "") }
    var thisWeekAccessibility: String { "\(thisWeekTitle), \(thisWeekSummary)" }
    var coverAccessibility: String { "\(Self.coverTitle), \(Self.coverCaption)" }
}

extension PublishedScheduleState {
    /// 디자인 17e 예시 값(가짜 데이터)
    static let sample = PublishedScheduleState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        nextWeekTitle: "다음 주 · 10월 5일 – 11일",
        isNewlyPublished: true,
        shifts: [
            PublishedShift(weekday: "월", day: 5, startText: "17:00", endText: "22:00", paidMinutes: 270, isHolidayPremium: false),
            PublishedShift(weekday: "수", day: 7, startText: "17:00", endText: "22:00", paidMinutes: 270, isHolidayPremium: false),
            PublishedShift(weekday: "금", day: 9, startText: "17:00", endText: "22:00", paidMinutes: 270, isHolidayPremium: true),
            PublishedShift(weekday: "토", day: 10, startText: "17:00", endText: "22:00", paidMinutes: 270, isHolidayPremium: false),
        ],
        nextWeekPaidMinutes: 1080,
        expectedPay: 243_000,
        includesHolidayPremium: true,
        thisWeekTitle: "이번 주 · 9월 28일 – 10월 4일",
        thisWeekDays: 3,
        thisWeekPaidMinutes: 870
    )
}
