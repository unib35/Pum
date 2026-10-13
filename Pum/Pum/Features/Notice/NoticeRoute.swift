import SwiftUI

enum NoticeRoute: String, CaseIterable, Hashable {
    case noticeDetail = "3b"
    case newsFeed = "3a"
    case noticeReadStatus = "3d"
    case noticeCompose = "3c"
    case newsFeedInvite = "15d"

    var title: String {
        switch self {
        case .noticeDetail: "공지 상세"
        case .newsFeed: "소식"
        case .noticeReadStatus: "공지 확인 현황"
        case .noticeCompose: "공지 작성"
        case .newsFeedInvite: "소식 · 초대"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .noticeDetail:
            NoticeDetailView(state: .sample, onBack: router.back)
        case .newsFeed:
            newsFeed(.sample, router)
        case .noticeReadStatus:
            NoticeReadStatusView(state: .sample, onBack: router.back)
        case .noticeCompose:
            NoticeComposeView(
                state: .sample,
                onClose: router.back,
                onSend: { _, done in
                    done(true)
                    router.replace(with: .notice(.newsFeed))
                }
            )
        case .newsFeedInvite:
            newsFeed(.withInvite, router)
        }
    }

    static let connected: Set<Self> = [
        .noticeDetail, .newsFeed, .noticeReadStatus, .noticeCompose,
        .newsFeedInvite,
    ]


    @MainActor
    private func newsFeed(_ state: NewsFeedState, _ router: AppRouter) -> some View {
        NewsFeedView(
            state: state,
            onOpenContract: { _ in router.navigate(.employee(.contractReview)) },
            onOpenNotice: { _ in router.navigate(.notice(.noticeDetail)) },
            onOpenWorkplaceSwitcher: { router.navigate(.home(.workplaceSwitcher)) },
            onOpenInvite: { _ in router.navigate(.employee(.inviteCodeRetry)) }
        )
    }
}
