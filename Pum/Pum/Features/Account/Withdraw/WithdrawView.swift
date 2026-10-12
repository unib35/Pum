// UI-IOS-6b · REQ-090 — 회원 탈퇴 (하위 화면, 탭 바 없음).
// 정리할 사업장이 남아 있으면 하단 버튼 비활성. 동작은 모두 클로저(전송 · 확인 창은 원문 없음).
import SwiftUI

struct WithdrawView: View {
    let state: WithdrawState
    var onBack: () -> Void
    var onTransferOwnership: (WithdrawWorkplace) -> Void
    var onCloseWorkplace: (WithdrawWorkplace) -> Void
    /// 되돌릴 수 없는 탈퇴 — 확인 창 원문 없음, 클로저만
    var onWithdraw: () -> Void

    init(state: WithdrawState = .sample,
         onBack: @escaping () -> Void = {},
         onTransferOwnership: @escaping (WithdrawWorkplace) -> Void = { _ in },
         onCloseWorkplace: @escaping (WithdrawWorkplace) -> Void = { _ in },
         onWithdraw: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onTransferOwnership = onTransferOwnership
        self.onCloseWorkplace = onCloseWorkplace
        self.onWithdraw = onWithdraw
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "회원 탈퇴", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    Text("\(WithdrawState.headingFirstLine)\n\(WithdrawState.headingSecondLine)")
                        .pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, PumTokens.Space.s8)
                    ForEach(state.workplaces) { workplace in
                        WithdrawWorkplaceCard(workplace: workplace,
                                              onTransfer: { onTransferOwnership(workplace) },
                                              onClose: { onCloseWorkplace(workplace) })
                    }
                    consequencesCard
                    Text(state.staffNote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    private var consequencesCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                Text(state.consequencesTitle).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, PumTokens.Space.s4)
                ForEach(state.consequences) { item in
                    HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                        Text("\u{2022}").accessibilityHidden(true)
                        Text(item.attributed).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .pumText(.footnote)
                    .foregroundStyle(PumTokens.ColorToken.gray700)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(item.plainText))
                }
            }
            .padding(PumTokens.Space.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            PumButton(title: state.withdrawTitle, action: onWithdraw)
                .disabled(!state.canWithdraw)
                .accessibilityHint(Text(state.blockedReason ?? ""))
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s8)
        .background(PumColor.bgApp)
    }
}

// MARK: - 정리할 사업장 카드

private struct WithdrawWorkplaceCard: View {
    let workplace: WithdrawWorkplace
    let onTransfer: () -> Void
    let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric private var tile = PumLayout.avatar + PumTokens.Space.s8 // 원문 타일 44

    var body: some View {
        PumCard(attention: true) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    HStack(spacing: PumTokens.Space.s12) {
                        Text(workplace.initial)
                            .pumText(.callout, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: tile, height: tile)
                            .background(PumColor.accent, in: RoundedRectangle(cornerRadius: tile * PumLayout.storeTileRadiusRatio, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            Text(workplace.name).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                            Text(workplace.statusText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusAttention)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(workplace.message).pumText(.footnote).foregroundStyle(PumTokens.ColorToken.gray700)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(workplace.spoken))
                buttons
            }
            .padding(PumTokens.Space.s20)
        }
        .accessibilityElement(children: .contain)
    }

    /// 글자가 커지면(접근성 크기) 위아래로 쌓는다.
    @ViewBuilder private var buttons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) {
                PumButton(title: WithdrawState.transferTitle, size: .small, action: onTransfer)
                PumButton(title: WithdrawState.closeTitle, kind: .outline, size: .small, action: onClose)
            }
        } else {
            WithdrawButtonRow(spacing: PumTokens.Space.s8) { // 원문 폭 비율 약 9 : 7(360 : 280)
                PumButton(title: WithdrawState.transferTitle, size: .small, action: onTransfer)
                PumButton(title: WithdrawState.closeTitle, kind: .outline, size: .small, action: onClose)
            }
        }
    }
}

/// 버튼 두 개를 받은 폭 그대로 9 : 7로 나눈다(우선순위로 다투면 한쪽이 찌그러짐)
private struct WithdrawButtonRow: Layout {
    var spacing: CGFloat
    private let firstShare: CGFloat = 9
    private let totalShare: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let usable = max(width - spacing, 0)
        let first = usable * firstShare / totalShare
        var height: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let w = index == 0 ? first : usable - first
            height = max(height, subview.sizeThatFits(ProposedViewSize(width: w, height: nil)).height)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let usable = max(bounds.width - spacing, 0)
        let first = usable * firstShare / totalShare
        subviews[0].place(at: bounds.origin, proposal: ProposedViewSize(width: first, height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.minX + first + spacing, y: bounds.minY),
                          proposal: ProposedViewSize(width: usable - first, height: bounds.height))
    }
}

#Preview("회원 탈퇴 6b") { WithdrawView() }
#Preview("회원 탈퇴 정리 끝") { WithdrawView(state: .cleared) }
