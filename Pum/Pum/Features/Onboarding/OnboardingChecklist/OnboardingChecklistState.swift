// UI-IOS-6i · REQ-061 — 입사 준비(직원): 체크리스트 · 서류 업로드 화면 데이터
// 단계 · 완료 여부 · 문구 · 계좌 가림(****821)은 서버가 준 값 그대로. 화면에서 만들지 않는다.
// 계좌 · 서류 내용은 로그에 남기지 않는다.
import Foundation

nonisolated struct OnboardingStep: Equatable, Sendable, Identifiable {
    let id: Int
    let title: String
    /// 완료는 결과 요약(예: 「10/03 초대 수락」), 해야 함은 이유(예: 「음식점은 …」)
    let detail: String
    let isDone: Bool

    var accessibilityText: String {
        "\(title), \(isDone ? "완료" : "해야 함"), \(detail)"
    }
}

/// 남은 서류 올리기 상자 — 남은 서류가 없으면 서버가 주지 않는다(nil)
nonisolated struct OnboardingUploadBox: Equatable, Sendable {
    let title: String
    let note: String
}

nonisolated struct OnboardingChecklistState: Equatable, Sendable {
    let workplaceLine: String          // 서버가 준 「종민김밥 본점 · 첫 근무 10월 5일」
    let steps: [OnboardingStep]        // 서버가 준 순서
    let upload: OnboardingUploadBox?

    static let backTitle = "입사 준비"
    static let title = "입사 준비"
    static let takePhotoTitle = "촬영"
    static let pickFileTitle = "앨범 \u{00B7} 파일"

    var doneCount: Int { steps.filter(\.isDone).count }
    var totalCount: Int { steps.count }

    var accessibilityTitle: String { "\(Self.title), \(totalCount)개 중 \(doneCount)개 끝" }

    /// 막대 비율 — 완료 수 / 전체 수만. 전체가 0이면 0
    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return min(max(Double(doneCount) / Double(totalCount), 0), 1)
    }

    /// 원문 캡처 값
    static let sample = OnboardingChecklistState(
        workplaceLine: "종민김밥 본점 \u{00B7} 첫 근무 10월 5일",
        steps: [
            OnboardingStep(id: 1, title: "사업장 참여", detail: "10/03 초대 수락", isDone: true),
            OnboardingStep(id: 2, title: "본인 확인", detail: "휴대폰 인증", isDone: true),
            OnboardingStep(id: 3, title: "근로조건 확인", detail: "시급 12,000원 \u{00B7} 월\u{00B7}수\u{00B7}금", isDone: true),
            OnboardingStep(id: 4, title: "근로계약서 서명", detail: "10/03 체결", isDone: true),
            OnboardingStep(id: 5, title: "급여계좌 등록", detail: "카카오뱅크 ****821", isDone: true),
            OnboardingStep(id: 6, title: "건강진단결과서(보건증)", detail: "음식점은 근무 시작 전에 제출해야 해요", isDone: false),
            OnboardingStep(id: 7, title: "사업장 안내 확인", detail: "유니폼 \u{00B7} 위생 규칙 \u{00B7} 마감 순서", isDone: true),
        ],
        upload: OnboardingUploadBox(
            title: "보건증 올리기",
            note: "만료일을 읽어 30일 전에 알려드려요 \u{00B7} 사장님만 볼 수 있어요"))
}
