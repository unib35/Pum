// UI-IOS-21n · REQ-095 · M38 — 사장님 홈 불러오기 실패: 마지막으로 받은 화면 유지 + 다시 시도(오프라인 6q와 구분)
import SwiftUI

/// 21n 원문 문구. 받은 시각(`15:12`)은 서버가 준 글자를 그대로 쓴다.
nonisolated enum OwnerHomeLoadFailed {
    /// 21n 원문의 마지막으로 받은 시각
    static let sampleSince = "15:12"
    static let title = "새 정보를 불러오지 못했어요"
    static let retryTitle = "다시 시도"

    /// 제목 위 작은 회색 줄(1aq의 날짜 줄 자리)
    static func sinceLine(_ since: String) -> String { "\(since) 기준" }
    static func reason(since: String) -> String { "\(since)에 받은 화면이에요 · 출퇴근 기록은 그대로 저장돼요" }
    static func announcement(since: String) -> String { "\(title), \(reason(since: since))" }

    /// M38 흐림 정도(.6, 토큰 없음)
    static let staleOpacity: Double = 0.6
}

/// 제목 블록 아래 실패 안내 카드 — 연주황 원 「!」 · 제목 · 이유 · 다시 시도
struct OwnerHomeLoadFailedCard: View {
    let since: String
    let onRetry: () -> Void

    var body: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    info.frame(maxWidth: .infinity, alignment: .leading)
                    retry
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    info
                    retry
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
        }
    }

    private var info: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Text("!")
                .pumText(.callout, weight: .heavy)
                .foregroundStyle(PumColor.statusAttention)
                .frame(width: PumLayout.avatar, height: PumLayout.avatar)
                .background(PumColor.statusAttentionSoft, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(OwnerHomeLoadFailed.title).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                Text(OwnerHomeLoadFailed.reason(since: since)).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(OwnerHomeLoadFailed.announcement(since: since)))
    }

    private var retry: some View {
        PumChipButton(title: OwnerHomeLoadFailed.retryTitle, kind: .neutral, action: onRetry)
    }
}

/// 오래된 화면 표시 — 마지막으로 받은 값을 흐리게(M38 .6 · fast). 눌러서 처리하는 건 그대로 된다.
private struct StaleDim: ViewModifier {
    let isStale: Bool
    func body(content: Content) -> some View {
        content
            .opacity(isStale ? OwnerHomeLoadFailed.staleOpacity : 1)
            .animation(PumMotion.fast, value: isStale)
    }
}

extension View {
    func ownerHomeStale(_ isStale: Bool) -> some View { modifier(StaleDim(isStale: isStale)) }
}
