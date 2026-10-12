// UI-IOS-1ah · REQ-027 — 근무기록 액션 시트. iOS 기본 액션 시트 모양(떠 있는 둥근 카드 3장).
// 공통 C9 바텀시트(손잡이 · 위 모서리만 둥근 판)와 모양이 달라 화면 전용 — 공통 후보로 보고.
import SwiftUI

struct OwnerRecordActionsSheet: View {
    let state: OwnerRecordActionsState
    var onAction: (OwnerRecordAction) -> Void = { _ in }
    var onCancel: () -> Void = {}

    // 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 행 높이 약 56 (터치 최소 44 이상)
        static let rowMinHeight: CGFloat = 56
        /// 카드 사이 간격 약 8, 화면 좌우 안쪽 약 10~12 → s12
        static let cardGap = PumTokens.Space.s8
        static let sideInset = PumTokens.Space.s12
    }
    @ScaledMetric private var rowMinHeight = Local.rowMinHeight

    var body: some View {
        // 글자가 커져 화면을 넘으면 안에서 스크롤
        ViewThatFits(in: .vertical) {
            cards
            ScrollView { cards }.scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, Local.sideInset)
        .padding(.bottom, Local.cardGap)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        // 모달이라 뒤의 막에 VoiceOver가 닿지 않는다 — 두 손가락 문지르기로 닫는다
        .accessibilityAction(.escape, onCancel)
    }

    private var cards: some View {
        VStack(spacing: Local.cardGap) {
            menuCard
            guideCard
            cancelCard
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let r = PumTokens.Radius.xl
        return VStack(spacing: 0) { content() }
            .frame(maxWidth: .infinity)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
    }

    private var hairline: some View { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }

    // B1. 메뉴 카드
    private var menuCard: some View {
        card {
            Text(state.sheetTitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: rowMinHeight)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .accessibilityAddTraits(.isHeader)
            ForEach(state.menu, id: \.self) { item in
                hairline
                Button(role: item.isDestructive ? .destructive : nil) { onAction(item) } label: {
                    Text(item.title)
                        // 17px: 일반 동작 500 파랑, 삭제 600 빨강
                        .pumText(.headline, weight: item.isDestructive ? .semibold : .medium)
                        .foregroundStyle(item.isDestructive ? PumColor.statusDanger : PumColor.accent)
                        .frame(maxWidth: .infinity, minHeight: rowMinHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(item.accessibilityHint ?? ""))
            }
        }
    }

    // B2. 안내 카드
    private var guideCard: some View {
        card {
            Text("\(Text(OwnerRecordActionsState.guideRuleTitle).fontWeight(.bold).foregroundStyle(PumColor.textPrimary))\(Text(OwnerRecordActionsState.guideBefore).foregroundStyle(PumColor.textSecondary))\(Text(OwnerRecordActionsState.guideCorrection).fontWeight(.bold).foregroundStyle(PumColor.textSecondary))\(Text(OwnerRecordActionsState.guideAfter).foregroundStyle(PumColor.textSecondary))")
                .pumText(.caption) // 12px
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PumTokens.Space.s12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.guideText))
        }
    }

    // B3. 취소 카드
    private var cancelCard: some View {
        card {
            Button(action: onCancel) {
                Text(OwnerRecordActionsState.cancelText).pumText(.headline) // 17px 600
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: rowMinHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
