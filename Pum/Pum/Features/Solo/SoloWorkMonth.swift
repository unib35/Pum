import Foundation

/// 저장된 근무 → 20e 근무 목록 · 20f 시트 값. 시간은 0시부터의 분, 날짜는 SeoulDayKey.
enum SoloWorkMonth {
    static func dayID(_ key: Int) -> String {
        String(format: "%04d-%02d-%02d", SeoulDayKey.year(key), SeoulDayKey.month(key), SeoulDayKey.day(key))
    }

    static func dayKey(_ id: String) -> Int? {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return SeoulDayKey.make(year: parts[0], month: parts[1], day: parts[2])
    }

    /// 「10월 7일 수」
    static func dateText(_ key: Int) -> String {
        let names = ["월", "화", "수", "목", "금", "토", "일"]
        let weekday = SeoulDayKey.weekday(key)
        let name = (1...7).contains(weekday) ? " \(names[weekday - 1])" : ""
        return "\(SeoulDayKey.month(key))월 \(SeoulDayKey.day(key))일\(name)"
    }

    static func workedMinutes(_ day: WorkDay) -> Int { max(day.endMinute - day.startMinute - day.breakMinutes, 0) }

    static func plannedMinutes(_ terms: WorkTerms?) -> Int {
        guard let terms else { return 0 }
        let end = WorkDay.normalizedEnd(start: terms.startMinute, end: terms.endMinute)
        return max(end - terms.startMinute - terms.breakMinutes, 0)
    }

    /// 「+1시간」 · 「−30분」 · 같으면 nil
    static func deltaText(_ minutes: Int) -> String? {
        guard minutes != 0 else { return nil }
        return (minutes > 0 ? "+" : "\u{2212}") + SoloFormat.duration(abs(minutes))
    }

    static func deltaReadout(_ minutes: Int) -> String? {
        guard minutes != 0 else { return nil }
        return SoloFormat.duration(abs(minutes)) + (minutes > 0 ? " 더" : " 덜")
    }

    static func row(_ day: WorkDay, employee: Employee, today: Int) -> AppLessWorkDay {
        let id = dayID(day.dayKey)
        let date = dateText(day.dayKey)
        if day.status == .absent {
            return AppLessWorkDay(id: id, dateText: date, timeText: "결근", durationText: nil, extraText: nil,
                                  extraReadout: nil, noteText: day.reason.isEmpty ? nil : day.reason, status: .edited)
        }
        if day.endMinute == 0 && day.startMinute == 0 {
            return AppLessWorkDay(id: id, dateText: date, timeText: "쉬는 날", durationText: nil, extraText: nil,
                                  extraReadout: nil, noteText: day.reason.isEmpty ? nil : day.reason, status: .edited)
        }
        let time = PumFormat.timeRange(SoloFormat.clock(day.startMinute), SoloFormat.clock(day.endMinute))
        if day.dayKey > today && day.status == .scheduled {
            return AppLessWorkDay(id: id, dateText: date, timeText: time, durationText: nil, extraText: nil,
                                  extraReadout: nil, noteText: "예정", status: .upcoming)
        }
        let worked = workedMinutes(day)
        let delta = day.status == .scheduled ? 0 : worked - plannedMinutes(plannedTerms(employee, day.dayKey))
        return AppLessWorkDay(id: id, dateText: date, timeText: time, durationText: SoloFormat.duration(worked),
                              extraText: deltaText(delta), extraReadout: deltaReadout(delta),
                              noteText: day.status == .extra ? "추가 근무" : nil,
                              status: day.status == .scheduled ? .asPlanned : .edited)
    }

    /// 근무 요일이 아닌 날은 예정 0분
    static func plannedTerms(_ employee: Employee, _ dayKey: Int) -> WorkTerms? {
        WorkDayFixUseCase.isPlannedDay(employee, dayKey) ? employee.terms(on: dayKey) : nil
    }

    static func staffState(_ employee: Employee, year: Int, month: Int, today: Int) -> AppLessStaffState {
        let terms = employee.terms(on: today) ?? employee.terms(on: .max)
        let range = SeoulDayKey.monthRange(year: year, month: month)
        let days = (employee.workDays ?? []).filter { range.contains($0.dayKey) }.sorted { $0.dayKey < $1.dayKey }
        let photos = employee.contractPhotos?.count ?? 0
        return AppLessStaffState(
            name: employee.name,
            summaryText: terms.map(summary) ?? "",
            sectionTitle: "\(month)월 근무",
            days: days.map { row($0, employee: employee, today: today) },
            contractText: photos > 0 ? "종이 계약서 · 사진 \(photos)장" : "사진 없음",
            isSolo: true)
    }

    /// 「월–금 09–18 · 10,320원」
    static func summary(_ terms: WorkTerms) -> String {
        let wage = PumFormat.amount(terms.amount) + "원" + (terms.wageType == .monthly ? "/월" : "")
        return "\(SoloFormat.weekdays(terms.workWeekdays)) \(SoloFormat.hours(start: terms.startMinute, end: terms.endMinute)) \u{00B7} \(wage)"
    }

    static func sheetState(_ employee: Employee, dayKey: Int) -> DayFixState {
        let terms = plannedTerms(employee, dayKey)
        let planned = terms.map {
            "예정 \(PumFormat.timeRange(SoloFormat.clock($0.startMinute), SoloFormat.clock($0.endMinute))) · 휴게 \(DayFixState.breakText($0.breakMinutes))"
        } ?? "예정 근무 없는 날"
        let day = (employee.workDays ?? []).first { $0.dayKey == dayKey }
        let kind: DayFixKind
        switch day {
        case .some(let d) where d.status == .absent: kind = .absent
        case .some(let d) where d.startMinute == 0 && d.endMinute == 0: kind = .dayOff
        case .some: kind = .worked
        case .none: kind = terms == nil ? .dayOff : .worked
        }
        let start = day.map(\.startMinute) ?? terms?.startMinute ?? 9 * 60
        let end = day.map(\.endMinute) ?? terms?.endMinute ?? 18 * 60
        let rest = day.map(\.breakMinutes) ?? terms?.breakMinutes ?? 0
        return DayFixState(
            dayID: dayID(dayKey), dateTitle: dateText(dayKey), plannedText: planned, initialKind: kind,
            initialStart: SoloFormat.clock(kind == .worked ? start : (terms?.startMinute ?? 9 * 60)),
            initialEnd: SoloFormat.clock(kind == .worked ? end : (terms?.endMinute ?? 18 * 60)),
            initialBreakMinutes: kind == .worked ? rest : (terms?.breakMinutes ?? 0),
            initialReason: day?.reason ?? "", preview: nil, isSolo: true)
    }

    /// 20f 「인정 근무 · 예정보다」 — 기기 안 계산(DEC-029). 가산 여부 문구는 계산 모듈이 정하므로 넣지 않는다
    static func preview(_ input: DayFixInput, employee: Employee) -> DayFixPreview? {
        guard input.kind == .worked, let key = dayKey(input.dayID),
              let start = input.start.flatMap(DayFixState.minutes), let end = input.end.flatMap(DayFixState.minutes)
        else { return nil }
        let span = WorkDay.normalizedEnd(start: start, end: end) - start
        let worked = max(span - (input.breakMinutes ?? 0), 0)
        let delta = worked - plannedMinutes(plannedTerms(employee, key))
        return DayFixPreview(
            input: input, recognizedText: SoloFormat.duration(worked), recognizedReadout: SoloFormat.duration(worked),
            deltaDetail: nil, deltaText: deltaText(delta) ?? "같음", deltaReadout: deltaReadout(delta) ?? "같음")
    }
}
