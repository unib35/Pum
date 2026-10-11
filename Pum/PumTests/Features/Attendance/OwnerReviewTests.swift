// UI-IOS-1r — 확인 필요 근무: 유형별 배지 · 버튼 구성, 문구, 아바타 글자, 세그먼트 숫자
import Testing
@testable import Pum

struct OwnerReviewTests {
    let s = OwnerReviewState.sample

    @Test func 유형별_배지_색() {
        #expect(OwnerReviewKind.overtime.badgeKind == .attention)
        #expect(OwnerReviewKind.late.badgeKind == .attention)
        #expect(OwnerReviewKind.missingClockOut.badgeKind == .problem)
        #expect(OwnerReviewKind.unscheduled.badgeKind == .waiting)
        #expect(s.items.map(\.badgeText) == ["연장근무", "퇴근 기록 없음", "지각 15분", "예정 없는 근무"])
    }

    @Test func 유형별_버튼_구성() {
        let i = s.items
        #expect(i[0].kind.secondary.title == "수정" && i[0].kind.secondary.kind == .outline)
        #expect(i[0].primaryTitle == "인정" && i[0].kind.primaryKind == .primary)
        #expect(i[1].kind.secondary.title == "직접 입력" && i[1].kind.secondary.kind == .outline)
        #expect(i[1].primaryTitle == "15:00 기록" && i[1].kind.primaryKind == .dark)
        #expect(i[2].kind.secondary.title == "수정" && i[2].primaryTitle == "확인")
        #expect(i[3].kind.secondary.title == "거절" && i[3].kind.secondary.kind == .dangerOutline)
        #expect(i[3].primaryTitle == "인정" && i[3].kind.primaryKind == .primary)
        #expect(OwnerReviewKind.missingClockOut.secondary.action == .manualInput)
        #expect(OwnerReviewKind.missingClockOut.primaryAction == .recordPlannedEnd)
        #expect(OwnerReviewKind.unscheduled.secondary.action == .reject)
        #expect(OwnerReviewKind.late.primaryAction == .confirm)
    }

    @Test func 시간_금액_문구() {
        #expect(s.items[0].plannedRange == "17:00 \u{2013} 22:00")
        #expect(s.items[0].actualLead == "16:58 \u{2013} ")
        #expect(s.items[0].actualEndText == "23:02")
        #expect(s.items[1].actualEndText == "\u{2014}")
        #expect(s.items[0].amount?.text == "+12,400원")
        #expect(s.items[2].amount?.text == "\u{2212}3,000원")
        #expect(s.items[3].amount?.text == "48,000원")
        #expect(s.items[2].explanationText == "예정 09:00 \u{2192} 실제 09:15 출근 \u{00B7} ")
        #expect(s.items[1].explanationText == "예정 퇴근 15:00으로 처리할까요?")
        #expect(s.items[2].plannedRange == nil)
        #expect(!s.items[3].hasTimeBox)
    }

    @Test func 아바타_글자는_원문과_같다() {
        #expect(s.items.map(\.avatarInitial) == ["하", "서", "유", "우"])
    }

    @Test func 세그먼트_숫자와_바닥_문구() {
        #expect(s.needsReviewCount == 4)
        #expect(s.processedTitle == "처리됨 12")
        #expect(s.autoConfirmedText == "정상 근무 12건은 정책에 따라 자동 확정됐어요")
        #expect(s.workTabBadge == 0)
    }

    @Test func 보이스오버_카드_문장() {
        #expect(s.items[0].accessibilitySummary ==
            "김하늘, 10월 2일 금요일, 연장근무, 예정 17:00부터 22:00, 실제 16:58부터 23:02, 예정보다 1시간 2분 늦게 퇴근, 12,400원 추가")
    }
}
