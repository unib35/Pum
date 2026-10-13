// UI-IOS-10b — 계약서 미리보기: 원문 값 · 조항 · 단계 낭독 · 서명하고 보내기 잠금
import Testing
@testable import Pum

struct ContractPreviewTests {
    let s = ContractPreviewState.sample

    @Test func 원문_문구() {
        #expect(s.docTitle == "단시간근로자 표준근로계약서")
        #expect(s.pageText == "1 / 3쪽")
        #expect(ContractPreviewState.stepText == "2/2")
        #expect(ContractPreviewState.stepSpoken == "2단계 중 2단계")
        #expect(ContractPreviewState.signTitle == "서명하고 보내기")
        #expect(ContractPreviewState.footnote == "직원이 서명해야 계약이 시작돼요")
    }

    @Test func 조항_6줄_4번만_둘째줄() {
        #expect(s.clauses.map(\.number) == ["1.", "2.", "3.", "4.", "5.", "6."])
        #expect(s.clauses.filter { $0.note != nil }.map(\.id) == [4])
        #expect(s.clauses[3].note == "(휴게 30분, 주 소정근로 18시간)")
        #expect(s.clauses[5].spoken == "6. 주휴일 : 매주 일요일")
    }

    @Test func 단계_3행_모두_미완료_낭독() {
        #expect(s.steps.map(\.title) == ["사업주 서명", "김하늘 서명", "양쪽 문서함에 보관"])
        #expect(s.steps.allSatisfy { !$0.isDone })
        #expect(s.steps[0].spoken == "사업주 서명, 지금 · 휴대폰 본인확인 후, 아직 안 함")
        var done = s.steps[0]
        done.isDone = true
        #expect(done.spoken == "사업주 서명, 지금 · 휴대폰 본인확인 후, 완료")
    }

    @Test func 보내기는_한번만_실패면_풀림() {
        var lock = ContractPreviewLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish(success: false)
        #expect(!lock.isSending)
    }

    @Test func 성공이면_잠근_채() {
        var lock = ContractPreviewLock()
        _ = lock.begin()
        lock.finish(success: true)
        #expect(lock.isSending)
    }
}
