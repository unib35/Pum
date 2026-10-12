// UI-IOS-6i · REQ-061 — 입사 준비 화면 데이터 검사
import Testing
@testable import Pum

struct OnboardingChecklistTests {
    @Test func 원문_값() {
        let s = OnboardingChecklistState.sample
        #expect(s.workplaceLine == "종민김밥 본점 \u{00B7} 첫 근무 10월 5일")
        #expect(s.totalCount == 7)
        #expect(s.doneCount == 6)
        #expect(s.steps[4].detail == "카카오뱅크 ****821")
        #expect(s.steps[5].title == "건강진단결과서(보건증)")
        #expect(s.upload?.title == "보건증 올리기")
        #expect(s.upload?.note == "만료일을 읽어 30일 전에 알려드려요 \u{00B7} 사장님만 볼 수 있어요")
        #expect(OnboardingChecklistState.pickFileTitle == "앨범 \u{00B7} 파일")
    }

    @Test func 읽기_문구() {
        let s = OnboardingChecklistState.sample
        #expect(s.accessibilityTitle == "입사 준비, 7개 중 6개 끝")
        #expect(s.steps[5].accessibilityText == "건강진단결과서(보건증), 해야 함, 음식점은 근무 시작 전에 제출해야 해요")
        #expect(s.steps[0].accessibilityText == "사업장 참여, 완료, 10/03 초대 수락")
    }

    @Test func 진행_비율_경계() {
        let none = OnboardingChecklistState(workplaceLine: "", steps: [], upload: nil)
        #expect(none.progressFraction == 0)
        let todo = OnboardingStep(id: 1, title: "a", detail: "b", isDone: false)
        let done = OnboardingStep(id: 2, title: "a", detail: "b", isDone: true)
        #expect(OnboardingChecklistState(workplaceLine: "", steps: [todo], upload: nil).progressFraction == 0)
        #expect(OnboardingChecklistState(workplaceLine: "", steps: [done], upload: nil).progressFraction == 1)
        #expect(abs(OnboardingChecklistState.sample.progressFraction - 6.0 / 7.0) < 0.000_001)
    }

    @Test func 남은_서류가_없으면_상자를_숨긴다() {
        let s = OnboardingChecklistState.sample
        let finished = OnboardingChecklistState(workplaceLine: s.workplaceLine, steps: s.steps, upload: nil)
        #expect(finished.upload == nil)
        #expect(s.upload != nil)
    }
}
