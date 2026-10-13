import SwiftUI

enum CommsRoute: String, CaseIterable, Hashable {
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
            NoticeDetailView(state: .sample)
        case .newsFeed:
            NewsFeedView(state: .sample)
        case .noticeReadStatus:
            NoticeReadStatusView(state: .sample)
        case .noticeCompose:
            NoticeComposeView(state: .sample)
        case .newsFeedInvite:
            NewsFeedView(state: .withInvite)
        }
    }

    static let connected: Set<Self> = []
}
