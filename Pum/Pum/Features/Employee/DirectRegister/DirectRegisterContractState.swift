// UI-IOS-20d · REQ-007 · REQ-060 · DEC-001 — 직접 등록 3/3 · 근로계약서
// 종이 계약서 사진을 허용하고, 「나중에」를 고르면 초대할 때 전자서명을 권한다.
// 사진 지우기 · 사진 0장일 때 동작 · 사본 체크가 「나중에」에서 보이는지는 원문에 없다(보고 사항).
import Foundation

nonisolated enum DirectRegisterContractMethod: Equatable, Sendable { case photo, later }

/// 호출자가 주는 계약서 사진(썸네일 이미지 로딩은 호출자 몫)
nonisolated struct DirectRegisterContractPhoto: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
}

/// 화면 초안
nonisolated struct DirectRegisterContractDraft: Equatable, Sendable {
    var method: DirectRegisterContractMethod
    var copyGiven: Bool
}

/// 등록으로 넘기는 값
nonisolated struct DirectRegisterContractValue: Equatable, Sendable {
    let method: DirectRegisterContractMethod
    /// 사진 방식일 때만 채운다
    let photoIDs: [String]
    /// 사진 방식일 때만 true가 될 수 있다
    let copyGiven: Bool
}

nonisolated struct DirectRegisterContractState: Equatable, Sendable {
    static let backTitle = "근로조건"
    static let title = "근로계약서"
    static let currentStep = 3
    static let subtitle = "근로조건이 들어간 계약서를 직원과 주고받아야 해요."
    static let photoTitle = "종이 계약서 사진 올리기"
    static let photoHint = "서명한 계약서를 찍어 보관해요"
    static let copyTitle = "직원에게 계약서 사본을 줬어요"
    static let laterTitle = "나중에 · 초대하면 전자서명"
    static let laterHint = "그때까지 계약서 없음으로 보여요"
    static let addSymbol = "+"
    static let addLabel = "사진 추가"
    static let registerTitle = "등록"
    static let footnote = "초대하면 같은 조건으로 전자 계약서를 보내드려요"

    let photos: [DirectRegisterContractPhoto]
    let method: DirectRegisterContractMethod
    let copyGiven: Bool
    /// MVP(DEC-033): 초대가 없어 「나중에」 줄 · 초대 안내를 숨기고, 사진 없이도 등록한다
    var isSolo = false

    var initialDraft: DirectRegisterContractDraft { .init(method: method, copyGiven: copyGiven) }

    /// 사진 방식인데 사진이 없으면 등록할 수 없다(원문 없음 — 임시)
    func canRegister(_ draft: DirectRegisterContractDraft) -> Bool {
        isSolo || draft.method == .later || !photos.isEmpty
    }

    func value(_ draft: DirectRegisterContractDraft) -> DirectRegisterContractValue {
        switch draft.method {
        case .photo: .init(method: .photo, photoIDs: photos.map(\.id), copyGiven: draft.copyGiven)
        case .later: .init(method: .later, photoIDs: [], copyGiven: false)
        }
    }

    // MARK: 읽기 문구

    static var stepReadout: String { DirectRegisterStepBar.readout(current: currentStep) }
    static var photoReadout: String { "\(photoTitle), \(photoHint)" }
    static var laterReadout: String { "\(laterTitle), \(laterHint)" }
    static func thumbReadout(_ photo: DirectRegisterContractPhoto) -> String { "\(photo.name), 사진" }

    // MARK: 예시

    static let sample = DirectRegisterContractState(
        photos: [.init(id: "p1", name: "계약서 1쪽"), .init(id: "p2", name: "계약서 2쪽")],
        method: .photo, copyGiven: true)
    static let empty = DirectRegisterContractState(photos: [], method: .photo, copyGiven: false)
    static let later = DirectRegisterContractState(photos: [], method: .later, copyGiven: false)
}
