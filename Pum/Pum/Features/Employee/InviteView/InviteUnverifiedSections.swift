// UI-IOS-21g · UI-IOS-5f · REQ-013 — 미인증 사업장 초대: 사업장 카드(인증 전) + 안내 카드.
// 제안된 근로조건은 원문에 없어 숨긴다. 이름 · 주소 · 상태 문구는 서버 값.
import SwiftUI

struct InviteUnverifiedSections: View {
    let state: InviteViewState

    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 44
    /// 안내 목록 원 24 — 글자와 함께 커진다(공통 후보: 5a StepCircle과 같은 모양)
    @ScaledMetric(relativeTo: .callout) private var circle = PumTokens.Space.s24

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            workplaceCard
            noticeCard
        }
    }

    // 사업장 카드 + 세로 행
    private var workplaceCard: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(state.initial).pumText(.headline, weight: .bold).foregroundStyle(.white)
                        .frame(width: workplaceTile, height: workplaceTile)
                        .background(state.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.workplaceName).pumText(.headline, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(state.subtitleText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    PumBadge(text: InviteViewState.unverifiedBadge, kind: .attention)
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.unverifiedCardAccessibility))
                row("대표자", state.unverifiedOwnerValue, muted: true)
                row("사업자등록", state.unverifiedBusinessValue, muted: true)
                row("초대한 사람", state.unverifiedInviterValue, muted: false)
            }
        }
    }

    /// 행: 넓으면 한 줄(값 오른쪽), 좁으면(큰 글자) 값이 아래로. 위 hairline은 카드 끝까지.
    private func row(_ label: String, _ value: String, muted: Bool) -> some View {
        let color = muted ? PumColor.textTertiary : PumColor.textPrimary
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                Text(label).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                Spacer(minLength: 0)
                Text(value).pumText(.callout).foregroundStyle(color).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(label).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                Text(value).pumText(.callout).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(value)"))
    }

    // 안내 카드
    private var noticeCard: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text("!").pumText(.callout, weight: .heavy).foregroundStyle(PumColor.statusAttention)
                        .frame(width: circle, height: circle)
                        .background(PumColor.statusAttentionSoft, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(InviteViewState.unverifiedNoticeTitle).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                        Text(InviteViewState.unverifiedNoticeDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .accessibilityElement(children: .combine)
                listRow(InviteViewState.unverifiedAllowedNow, allowed: true)
                listRow(InviteViewState.unverifiedAfterVerify, allowed: false)
            }
        }
    }

    /// 가능한 것 = 회색 원 + 먹색 체크 · 인증 후 = 빈 원(회색 테두리)
    private func listRow(_ text: String, allowed: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            Circle().fill(allowed ? PumColor.surfaceFill : PumColor.surfaceCard)
                .overlay {
                    if allowed {
                        Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(PumColor.textPrimary)
                    } else {
                        Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: 1.5)
                    }
                }
                .frame(width: circle, height: circle)
                .accessibilityHidden(true)
            Text(text).pumText(.callout, weight: .medium).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(text)) // 문구 자체가 「지금은 …」 · 「인증되면 …」이라 꼬리표를 붙이지 않는다
        .accessibilityAddTraits(allowed ? .isSelected : [])
    }
}

#Preview("21g 섹션") { InviteUnverifiedSections(state: .unverifiedSample).padding() }
