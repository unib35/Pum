import Foundation
import Observation

/// 직접 등록 20b → 20c → 20d 사이에 값을 모아 둔다. 등록하거나 처음 화면으로 돌아가면 비운다.
@MainActor @Observable
final class SoloRegisterFlow {
    struct Photo: Identifiable, Equatable {
        let id = UUID()
        let data: Data
    }

    var name = ""
    var phone = ""
    var hireDayKey = SeoulDayKey.from(.now)
    var isMonthly = false
    var amount = MinimumWage.hourly(year: SeoulDayKey.year(SeoulDayKey.from(.now)))
    var weekdays: Set<Int> = [1, 2, 3, 4, 5]
    var hours = PumTimeRangeValue(startMinutes: 9 * 60, endMinutes: 18 * 60, breakMinutes: 60)
    var photos: [Photo] = []

    func reset() {
        let fresh = SoloRegisterFlow()
        name = fresh.name
        phone = fresh.phone
        hireDayKey = fresh.hireDayKey
        isMonthly = fresh.isMonthly
        amount = fresh.amount
        weekdays = fresh.weekdays
        hours = fresh.hours
        photos = []
    }

    var registration: EmployeeRegistration {
        EmployeeRegistration(
            name: name, phone: phone.isEmpty ? nil : phone, hireDayKey: hireDayKey,
            wageType: isMonthly ? .monthly : .hourly, amount: amount, weekdays: weekdays,
            startMinute: hours.startMinutes, endMinute: hours.endMinutes, breakMinutes: hours.breakMinutes,
            contractPhotos: photos.map(\.data))
    }
}
