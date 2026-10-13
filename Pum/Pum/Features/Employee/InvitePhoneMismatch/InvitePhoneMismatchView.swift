// UI-IOS-15g · REQ-004 — 직원 온보딩: 번호가 다를 때 — 사장님 확인 후 소속(확정). 탭 바 없음.
import SwiftUI

struct InvitePhoneMismatchView: View {
    let state: InvitePhoneMismatchState
    var onBack: () -> Void = {}
    var onRequestConfirm: () -> Void = {}
    var onLoginWithInvitedNumber: () -> Void = {}

    /// 목업 사업장 색 네모 약 48 — 15c와 같은 값
    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: InvitePhoneMismatchState.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    Text(InvitePhoneMismatchState.headline).pumText(.title1).foregroundStyle(PumColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                    phoneCard
                    workplaceCard
                    Text(InvitePhoneMismatchState.notice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s18) // 블록 gap 14 + 제목 margin-top 4
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    private var phoneCard: some View {
        PumCard {
            VStack(spacing: 0) {
                row(InvitePhoneMismatchState.invitedLabel, state.invitedPhoneMasked,
                    spoken: state.invitedAccessibilityText, isLast: false)
                row(InvitePhoneMismatchState.loginLabel, state.loginPhone,
                    spoken: state.loginAccessibilityText, isLast: true)
            }
        }
    }

    private var workplaceCard: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s14) {
                    Text(state.initial).pumText(.headline, weight: .bold).foregroundStyle(.white)
                        .frame(width: workplaceTile, height: workplaceTile)
                        .background(state.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: PumTokens.Space.s8) { name; badge }
                            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { name; badge }
                        }
                        Text(state.subtitleText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, PumTokens.Space.s16)
                .padding(.horizontal, PumTokens.Space.s18)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.cardAccessibilityText))
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                row("대표", state.ownerName, spoken: "대표, \(state.ownerName)", isLast: false)
                row("역할", state.roleName, spoken: "역할, \(state.roleName)", isLast: false)
                row("초대 유효", state.expiryValue, spoken: "초대 유효, \(state.expiryValue)", isLast: true)
            }
        }
    }

    private var name: some View {
        Text(state.workplaceName).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    @ViewBuilder private var badge: some View {
        if state.isVerified { PumBadge(text: "\u{2713} 인증된 사업장", kind: .done) }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 라벨 아래로
    private func row(_ label: String, _ value: String, spoken: String, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(label)
                Spacer(minLength: 0)
                val(value).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(label)
                val(value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800) // 15px 400 #3A4150
    }

    private func val(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    private var actions: some View {
        VStack(spacing: PumTokens.Space.s10) {
            PumButton(title: InvitePhoneMismatchState.requestTitle, kind: .primary,
                      isLoading: state.isRequesting, action: onRequestConfirm)
            PumButton(title: InvitePhoneMismatchState.loginWithInvitedTitle, kind: .text,
                      action: onLoginWithInvitedNumber)
                .disabled(state.isRequesting) // 확인 요청 중에 다른 번호로 로그인이 겹치지 않게
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s10)
        .background(PumColor.bgApp)
    }
}

#Preview("15g") { InvitePhoneMismatchView(state: .sample) }
#Preview("15g · 큰 글자") { InvitePhoneMismatchView(state: .sample).dynamicTypeSize(.xxxLarge) }
