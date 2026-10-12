// UI-IOS-15c · REQ-003 · REQ-013 — 직원 온보딩: 가입 직후 인증한 번호로 받은 초대(확정). 탭 바 없음.
// 원문은 1건만 — 여러 건 화면은 원문 없음(만들지 않음).
import SwiftUI

struct InviteAfterSignupView: View {
    let state: InviteAfterSignupState
    var onConfirm: () -> Void = {}
    var onStartWithout: () -> Void = {}

    /// 목업 앱 표시 네모 약 28 — 1o와 같은 값
    @ScaledMetric(relativeTo: .callout) private var brandMark: CGFloat = 28
    /// 목업 사업장 색 네모 약 48 — 1o · 15f와 같은 값
    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 48

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s20) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    brand
                    Text(state.titleText).pumText(.title1).foregroundStyle(PumColor.textPrimary) // 목업 26px 700 → title1(28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                }
                card
                startWithoutRow
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    private var brand: some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text("품").pumText(.callout, weight: .heavy).foregroundStyle(.white)
                .frame(width: brandMark, height: brandMark)
                .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            Text(state.phoneLine).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary) // 13px 600
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.brandAccessibilityText))
    }

    private var card: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
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
                .padding(PumTokens.Space.s16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.cardAccessibilityText))
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                termRow("대표", state.ownerName, isLast: false)
                termRow("역할", state.roleName, isLast: false)
                termRow("초대 유효", state.expiryValue, isLast: true)
            }
        }
    }

    private var name: some View {
        Text(state.workplaceName).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    @ViewBuilder private var badge: some View {
        if state.isVerified { PumBadge(text: "\u{2713} 인증된 사업장", kind: .done) }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private func termRow(_ label: String, _ value: String, isLast: Bool) -> some View {
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
        .accessibilityLabel(Text("\(label), \(value)"))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800) // 15px 400 #3A4150
    }

    private func val(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    private var startWithoutRow: some View {
        PumCard {
            Button(action: onStartWithout) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text("초대 없이 시작").pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text("개인 모드 · 내 근무 기록 · 급여 계산기").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        }
    }

    private var actions: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: "초대 확인하기", kind: .primary, action: onConfirm)
            Text("확인하면 제안된 근로조건을 보여드려요").pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s4)
        .background(PumColor.bgApp)
    }
}

#Preview("15c") { InviteAfterSignupView(state: .sample) }
#Preview("15c · 큰 글자") { InviteAfterSignupView(state: .sample).dynamicTypeSize(.xxxLarge) }
