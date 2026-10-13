// UI-IOS-1ah · REQ-027 — 근무기록 액션 시트. iOS 기본 액션 시트 모양(떠 있는 둥근 카드 3장).
// 공통 C9 바텀시트(손잡이 · 위 모서리만 둥근 판)와 모양이 달라 화면 전용 — 공통 후보로 보고.
import SwiftUI

struct OwnerRecordActionsSheet: View {
    let state: OwnerRecordActionsState
    var onAction: (OwnerRecordAction) -> Void = { _ in }
    var onCancel: () -> Void = {}

    // 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 카드 사이 간격 8, 화면 좌우 · 아래 10(원문 padding 0 10 10)
        static let cardGap = PumTokens.Space.s8
        static let sideInset = PumTokens.Space.s10
        /// 행 안쪽 — 원문 padding 14 18
        static let rowPadY = PumTokens.Space.s14
        static let rowPadX = PumTokens.Space.s18
    }

    var body: some View {
        // 글자가 커져 화면을 넘으면 안에서 스크롤
        ViewThatFits(in: .vertical) {
            cards
            ScrollView { cards }.scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, Local.sideInset)
        .padding(.bottom, Local.sideInset)
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
        let r = PumTokens.Radius.lg // 원문 14
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
                .frame(maxWidth: .infinity)
                .padding(.top, Local.rowPadY) // 원문 padding 14 18 10
                .padding(.bottom, PumTokens.Space.s10)
                .padding(.horizontal, Local.rowPadX)
                .accessibilityAddTraits(.isHeader)
            ForEach(state.menu, id: \.self) { item in
                hairline
                Button(role: item.isDestructive ? .destructive : nil) { onAction(item) } label: {
                    Text(item.title)
                        // 17px: 일반 동작 500 파랑, 삭제 600 빨강
                        .pumText(.headline, weight: item.isDestructive ? .semibold : .medium)
                        .foregroundStyle(item.isDestructive ? PumColor.statusDanger : PumColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Local.rowPadY)
                        .padding(.horizontal, Local.rowPadX)
                        .frame(minHeight: PumTokens.Size.tapMin)
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
                .padding(.vertical, Local.rowPadY) // 원문 padding 14 18
                .padding(.horizontal, Local.rowPadX)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PumTokens.Space.s16) // 원문 padding 16 18
                    .padding(.horizontal, Local.rowPadX)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
