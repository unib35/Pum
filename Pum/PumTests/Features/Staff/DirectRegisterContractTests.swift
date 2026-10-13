// UI-IOS-20d · REQ-007 · REQ-060 — 직접 등록 3/3 근로계약서
import Testing
@testable import Pum

struct DirectRegisterContractTests {
    @Test func 원문_값() {
        let s = DirectRegisterContractState.sample
        #expect(s.method == .photo)
        #expect(s.copyGiven)
        #expect(s.photos.map(\.name) == ["계약서 1쪽", "계약서 2쪽"])
        #expect(DirectRegisterContractState.title == "근로계약서")
        #expect(DirectRegisterContractState.backTitle == "근로조건")
        #expect(DirectRegisterContractState.currentStep == 3)
        #expect(DirectRegisterContractState.laterTitle == "나중에 · 초대하면 전자서명")
        #expect(DirectRegisterContractState.laterHint == "그때까지 계약서 없음으로 보여요")
        #expect(DirectRegisterContractState.registerTitle == "등록")
        #expect(DirectRegisterContractState.footnote == "초대하면 같은 조건으로 전자 계약서를 보내드려요")
    }

    @Test func 등록_가능_조건() {
        let photo = DirectRegisterContractDraft(method: .photo, copyGiven: false)
        let later = DirectRegisterContractDraft(method: .later, copyGiven: false)
        #expect(DirectRegisterContractState.sample.canRegister(photo))
        #expect(!DirectRegisterContractState.empty.canRegister(photo))
        #expect(DirectRegisterContractState.empty.canRegister(later))
    }

    @Test func 넘기는_값() {
        let s = DirectRegisterContractState.sample
        let photo = s.value(.init(method: .photo, copyGiven: true))
        #expect(photo == .init(method: .photo, photoIDs: ["p1", "p2"], copyGiven: true))
        let later = s.value(.init(method: .later, copyGiven: true))
        #expect(later == .init(method: .later, photoIDs: [], copyGiven: false))
    }

    @Test func 읽기_문구() {
        #expect(DirectRegisterContractState.photoReadout == "종이 계약서 사진 올리기, 서명한 계약서를 찍어 보관해요")
        #expect(DirectRegisterContractState.thumbReadout(.init(id: "p1", name: "계약서 1쪽")) == "계약서 1쪽, 사진")
        #expect(DirectRegisterContractState.addLabel == "사진 추가")
        #expect(DirectRegisterContractState.stepReadout == "3단계 중 3단계")
    }
}
