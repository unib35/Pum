// DEC-029 · DEC-031 · REQ-071 — MVP 월급 계산(순수 함수). 규칙 설명 · 노무 검토 가정: 같은 폴더 README.md
import Foundation

nonisolated enum PayrollCalculator {
    /// 하루 법정근로(분)
    static let dailyLimitMinutes = 8 * 60
    /// 주 법정근로(분)
    static let weeklyLimitMinutes = 40 * 60
    /// 주휴 대상 주 소정근로 하한(분)
    static let weeklyHolidayThresholdMinutes = 15 * 60
    /// 월급제 통상시급 환산 시간(주 40시간 + 주휴 8시간 기준 월 209시간)
    static let monthlyStandardHours = 209

    static func calculate(_ input: PayrollInput) -> PayrollResult {
        let period = input.period
        let terms = input.terms
        let applyPremium = input.workplace.isFiveOrMore
        var trace: [PayrollTraceLine] = []
        func add(_ item: PayrollTraceItem, _ text: String) { trace.append(PayrollTraceLine(item: item, text: text)) }

        let weekMondays = period.overlappingWeekMondays
        let rangeStart = weekMondays.first ?? period.firstDay
        let rangeEnd = (weekMondays.last ?? period.lastDay).adding(days: 6)
        let records = input.records.filter { $0.date >= rangeStart && $0.date <= rangeEnd }
        let periodRecords = records.filter { period.contains($0.date) && !$0.isAbsent }

        // 날짜별 근무시간(휴일 근무는 연장 계산에서 따로 본다)
        var regularByDate: [PayrollDate: Int] = [:]
        var holidayByDate: [PayrollDate: Int] = [:]
        var absentDates: Set<PayrollDate> = []
        for r in records {
            if r.isAbsent { absentDates.insert(r.date); continue }
            if r.isHolidayWork {
                holidayByDate[r.date, default: 0] += r.workedMinutes
            } else {
                regularByDate[r.date, default: 0] += r.workedMinutes
            }
        }

        // 1) 근무 합계(기간 안)
        let workedMinutes = periodRecords.reduce(0) { $0 + $1.workedMinutes }
        let workDays = Set(periodRecords.filter { $0.workedMinutes > 0 }.map(\.date)).count

        // 2) 연장: 하루 8시간 초과 + 주 40시간 초과(하루 초과분과 중복 없이). 주는 월–일, 기간 밖 날도 누적에 쓴다.
        var dailyOvertime = 0
        var weeklyOvertime = 0
        for monday in weekMondays {
            var weekRegular = 0
            for offset in 0..<7 {
                let date = monday.adding(days: offset)
                let minutes = regularByDate[date] ?? 0
                let withinDay = min(minutes, dailyLimitMinutes)
                let overDay = minutes - withinDay
                let overWeek = max(0, weekRegular + withinDay - weeklyLimitMinutes)
                weekRegular = min(weeklyLimitMinutes, weekRegular + withinDay)
                if period.contains(date) {
                    dailyOvertime += overDay
                    weeklyOvertime += overWeek
                }
            }
        }
        let overtimeMinutes = dailyOvertime + weeklyOvertime

        // 3) 야간: 22:00–06:00과 겹친 분. 휴게는 야간 밖에서 쓴 것으로 보고, 인정 근무시간을 넘지 않게 한다.
        let nightMinutes = periodRecords.reduce(0) { $0 + min(nightOverlap($1), $1.workedMinutes) }

        // 4) 휴일: 날짜별 8시간 이내 · 초과
        var holidayWithin = 0
        var holidayOver = 0
        for (date, minutes) in holidayByDate where period.contains(date) {
            holidayWithin += min(minutes, dailyLimitMinutes)
            holidayOver += max(0, minutes - dailyLimitMinutes)
        }
        let holidayMinutes = holidayWithin + holidayOver

        // 기본급 · 가산 기준 시급
        let basePay: Int
        let premiumRate: Int
        switch terms.wage {
        case .hourly(let rate):
            basePay = PayrollRounding.won(rate * workedMinutes, over: 60)
            premiumRate = rate
            add(.basePay, "기본급 \(PayrollText.duration(workedMinutes)) × \(PayrollText.won(rate)) = \(PayrollText.won(basePay))")
        case .monthly(let salary):
            basePay = max(0, salary)
            premiumRate = PayrollRounding.won(basePay, over: monthlyStandardHours)
            add(.basePay, "기본급 월급 \(PayrollText.won(basePay))")
            add(.note, "월급제 결근 공제 없음(MVP)")
        }

        // 주휴수당(시급제만). 그 주의 일요일이 이 달에 있는 주만 이 달에 지급한다.
        var weeklyHolidayPay = 0
        var weeklyHolidayWeeks = 0
        switch terms.wage {
        case .monthly:
            add(.note, "월급제: 주휴수당은 월급에 포함")
        case .hourly(let rate):
            let weekly = terms.weeklyScheduledMinutes
            if weekly < weeklyHolidayThresholdMinutes {
                add(.note, "주 소정근로 \(PayrollText.duration(weekly)) — 15시간 미만이라 주휴수당 없음")
            } else {
                var cappedSum = 0
                for monday in weekMondays {
                    let sunday = monday.adding(days: 6)
                    let weekLabel = "\(monday.koreanLabel)–\(sunday.koreanLabel) 주"
                    guard period.contains(sunday) else {
                        add(.note, "\(weekLabel): 주의 마지막 날이 다음 달이라 주휴수당은 다음 달에 지급")
                        continue
                    }
                    let absences = (0..<7).map { monday.adding(days: $0) }.filter {
                        terms.scheduledWeekdays.contains($0.weekday) && absentDates.contains($0)
                    }
                    if let first = absences.first {
                        add(.note, "\(weekLabel): 결근(\(first.koreanLabel)) — 주휴수당 없음")
                        continue
                    }
                    weeklyHolidayWeeks += 1
                    cappedSum += min(weekly, weeklyLimitMinutes)
                }
                weeklyHolidayPay = PayrollRounding.won(rate * cappedSum, over: 300)
                if weeklyHolidayWeeks > 0 {
                    let capNote = weekly > weeklyLimitMinutes ? "(최대 8시간)" : ""
                    add(.weeklyHolidayPay, "주휴수당 \(weeklyHolidayWeeks)주 × 주 소정근로 \(PayrollText.duration(min(weekly, weeklyLimitMinutes))) ÷ 40 × 8\(capNote) × \(PayrollText.won(rate)) = \(PayrollText.won(weeklyHolidayPay))")
                }
            }
        }

        // 가산(상시 5인 이상만, 50%)
        var overtimePay = 0
        var nightPay = 0
        var holidayPay = 0
        if applyPremium {
            if case .monthly = terms.wage, overtimeMinutes + nightMinutes + holidayMinutes > 0 {
                add(.note, "통상시급 \(PayrollText.won(basePay)) ÷ \(monthlyStandardHours)시간 = \(PayrollText.won(premiumRate))(원 미만 반올림) — 월급제는 가산분만 계산")
            }
            if overtimeMinutes > 0 {
                overtimePay = PayrollRounding.won(premiumRate * overtimeMinutes, over: 120)
                add(.overtime, "연장 가산 \(PayrollText.duration(overtimeMinutes))(하루 8시간 초과 \(PayrollText.duration(dailyOvertime)) + 주 40시간 초과 \(PayrollText.duration(weeklyOvertime))) × \(PayrollText.won(premiumRate)) × 50% = \(PayrollText.won(overtimePay))")
            }
            if nightMinutes > 0 {
                nightPay = PayrollRounding.won(premiumRate * nightMinutes, over: 120)
                add(.night, "야간 가산 \(PayrollText.duration(nightMinutes))(22시–06시) × \(PayrollText.won(premiumRate)) × 50% = \(PayrollText.won(nightPay))")
            }
            if holidayMinutes > 0 {
                holidayPay = PayrollRounding.won(premiumRate * (holidayWithin + 2 * holidayOver), over: 120)
                var text = "휴일 가산 8시간 이내 \(PayrollText.duration(holidayWithin)) × \(PayrollText.won(premiumRate)) × 50%"
                if holidayOver > 0 {
                    text += " + 8시간 초과 \(PayrollText.duration(holidayOver)) × \(PayrollText.won(premiumRate)) × 100%"
                }
                add(.holiday, text + " = \(PayrollText.won(holidayPay))")
            }
        } else if overtimeMinutes + nightMinutes + holidayMinutes > 0 {
            add(.note, "상시 5인 미만 — 연장 · 야간 · 휴일 가산 없음")
        }

        let grossPay = basePay + weeklyHolidayPay + overtimePay + nightPay + holidayPay
        add(.gross, "지급 합계 \(PayrollText.won(grossPay))")

        // 공제
        var incomeTax = 0
        var localIncomeTax = 0
        switch input.workplace.deduction {
        case .none:
            add(.note, "공제 없음")
        case .business3_3:
            incomeTax = PayrollRounding.truncateToTen(grossPay * 3 / 100)
            localIncomeTax = PayrollRounding.truncateToTen(incomeTax / 10)
            add(.incomeTax, "소득세 \(PayrollText.won(grossPay)) × 3% = \(PayrollText.won(incomeTax))(10원 미만 절사)")
            add(.localIncomeTax, "지방소득세 소득세 \(PayrollText.won(incomeTax)) × 10% = \(PayrollText.won(localIncomeTax))(10원 미만 절사)")
        }
        let totalDeduction = incomeTax + localIncomeTax
        if totalDeduction > 0 || input.workplace.deduction != .none {
            add(.deductionTotal, "공제 합계 \(PayrollText.won(totalDeduction))")
        }
        let netPay = grossPay - totalDeduction
        add(.netPay, "실지급액 \(PayrollText.won(grossPay)) − \(PayrollText.won(totalDeduction)) = \(PayrollText.won(netPay))")

        return PayrollResult(
            basePay: basePay,
            weeklyHolidayPay: weeklyHolidayPay,
            overtimePay: overtimePay,
            nightPay: nightPay,
            holidayPay: holidayPay,
            grossPay: grossPay,
            incomeTax: incomeTax,
            localIncomeTax: localIncomeTax,
            totalDeduction: totalDeduction,
            netPay: netPay,
            workDays: workDays,
            workedMinutes: workedMinutes,
            overtimeMinutes: overtimeMinutes,
            nightMinutes: nightMinutes,
            holidayMinutes: holidayMinutes,
            weeklyHolidayWeeks: weeklyHolidayWeeks,
            trace: trace
        )
    }

    /// 근무 구간 [시작, 끝)이 야간(전날 22시–06시, 그날 22시–다음날 06시, …)과 겹친 분.
    static func nightOverlap(_ record: PayrollWorkRecord) -> Int {
        guard !record.isAbsent, record.endMinute > record.startMinute else { return 0 }
        var total = 0
        for k in -1...3 {
            let windowStart = k * 1440 + 22 * 60
            let windowEnd = windowStart + 8 * 60
            let overlap = min(record.endMinute, windowEnd) - max(record.startMinute, windowStart)
            if overlap > 0 { total += overlap }
        }
        return total
    }
}
