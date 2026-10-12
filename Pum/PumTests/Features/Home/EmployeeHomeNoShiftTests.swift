// UI-IOS-1au — 직원 홈(근무 없는 날) 계산 · 표시 문구
import Testing
@testable import Pum

struct EmployeeHomeNoShiftTests {
    let s = NoShiftHomeState.sample

    @Test func 인정_근무는_예정에서_휴게를_뺀다() {
        #expect(s.nextShift.plannedPaidMinutes == 270)
    }

    @Test func 예정_금액은_정수_원() {
        #expect(s.nextShift.plannedPay(hourlyWage: s.hourlyWage) == 54_000)
        #expect(s.plannedSummary == "인정 근무 4시간 30분 · 54,000원 예정")
    }

    @Test func 주간_요약_문구() {
        #expect(s.weekSummary == "이번 주 4일 · 19시간")
    }

    @Test func 다음_근무_문구() {
        #expect(s.nextShiftCaption == "다음 근무 · 내일 월요일")
        #expect(s.nextShiftRange == "17:00 \u{2013} 22:00")
    }

    @Test func 오늘은_일요일이고_근무일은_네_개() {
        #expect(s.week.filter(\.isToday).map(\.label) == ["일"])
        #expect(s.week.filter(\.hasShift).map(\.label) == ["월", "수", "금", "토"])
        #expect(s.upcoming.count == 3)
    }

    @Test func 그다음_근무_3건과_이번_달_값() {
        let s = NoShiftHomeState.sample
        #expect(s.upcoming.map(\.id) == ["수 7일", "금 9일", "토 10일"])
        #expect(s.upcoming.allSatisfy { $0.start == "17:00" && $0.end == "22:00" })
        let m = s.monthCardState
        #expect(m.monthTitle == "10월")
        #expect(m.monthPlannedMinutes == 82 * 60 + 30)
        #expect(m.monthExpectedPay == 1_188_000)
        #expect(m.monthDaysSummary == "17일 · 확정 2일")
    }
}

// UI-IOS-6u · 6v · REQ-094 — 업데이트 권장 시트 · 점검 예고 한 줄
struct EmployeeHomeNoticesTests {
    @Test func 기본은_둘_다_없다() {
        #expect(NoShiftHomeState.sample.updateNotice == nil)
        #expect(NoShiftHomeState.sample.maintenanceNotice == nil)
    }

    @Test func 업데이트_권장_원문_값() {
        let n = NoShiftHomeState.updateAvailable.updateNotice
        #expect(n?.meta == "1.4.3 · 12MB")
        #expect(n?.highlights == ["출근 QR 인식이 빨라졌어요", "명세서를 PDF로 저장할 수 있어요"])
        #expect(AppUpdateNotice.title == "새 버전이 있어요")
        #expect(AppUpdateNotice.laterTitle == "나중에")
        #expect(AppUpdateNotice.updateTitle == "업데이트")
        #expect(NoShiftHomeState.updateAvailable.maintenanceNotice == nil)
    }

    @Test func 점검_예고_원문_값과_읽기_문구() {
        let n = NoShiftHomeState.maintenanceNotice.maintenanceNotice
        #expect(n?.title == "10월 12일 월 02:00 \u{2013} 04:00 점검")
        #expect(MaintenanceNotice.detail == "출퇴근은 그대로 기록돼요 · 급여 · 요청은 점검 후")
        #expect(n?.spoken == "10월 12일 월 02:00 \u{2013} 04:00 점검, 출퇴근은 그대로 기록돼요 · 급여 · 요청은 점검 후")
        #expect(MaintenanceNotice.dismissTitle == "닫기")
        #expect(NoShiftHomeState.maintenanceNotice.updateNotice == nil)
    }

    @Test func 시트_제목_읽기_문구() {
        #expect(AppUpdateNotice.sample.spokenTitle == "새 버전이 있어요, 1.4.3, 12MB")
    }
}
