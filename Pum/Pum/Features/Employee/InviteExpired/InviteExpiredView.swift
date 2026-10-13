// UI-IOS-15f · REQ-002 — 직원 온보딩: 초대 만료, 사장님에게 다시 요청(확정). 탭 바 없음.
// 보낸 뒤 결과 화면은 디자인에 없다 — 만들지 않고 처리 중 잠금만 건다(실패하면 풀림).
import SwiftUI

struct InviteExpiredView: View {
    var state: InviteExpiredState = .sample
    var onBack: () -> Void = {}
    var onContactWorkplace: () -> Void = {}
    /// 보내기를 끝내면 done(성공 여부)를 부른다 — 실패하면 다시 누를 수 있다
    var onRequestAgain: (_ done: @escaping (Bool) -> Void) -> Void = { $0(false) } // 연결 전 기본값은 미전송 — 성공처럼 보이지 않게

    @State private var lock = InviteRequestLock()
    /// 목업 사업장 색 네모 약 48 — InviteAccept(1o)와 같은 값, 큰 글자에서 글자와 함께 커진다(공통 후보)
    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "초대", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s20) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        Text("초대 기간이 지났어요").pumText(.title2).foregroundStyle(PumColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(state.expiredLine).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray700) // 14px 400 #5B6170
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    card
                    contactRow
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 3. 사업장 카드
    private var card: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(state.initial).pumText(.headline, weight: .bold).foregroundStyle(.white) // 17px 700
                        .frame(width: workplaceTile, height: workplaceTile)
                        .background(state.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                        .accessibilityHidden(true)
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
                .accessibilityElement(children: .combine)
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                termRow("대표", state.ownerName, valueColor: PumColor.textPrimary, isLast: false, spoken: nil)
                termRow("역할", state.roleName, valueColor: PumColor.textPrimary, isLast: false, spoken: nil)
                termRow("초대 유효", state.expiryValue, valueColor: PumColor.statusDanger, isLast: true,
                        spoken: state.expiryAccessibilityText)
            }
        }
    }

    private var name: some View {
        Text(state.workplaceName).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700 → body(15)
    }

    /// 인증된 사업장만 — 미인증이면 숨김. StaffInvite와 같은 PumBadge.done
    @ViewBuilder private var badge: some View {
        if state.isVerified { PumBadge(text: "\u{2713} 인증된 사업장", kind: .done) }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private func termRow(_ label: String, _ value: String, valueColor: Color, isLast: Bool, spoken: String?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(label)
                Spacer(minLength: 0)
                val(value, valueColor).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(label)
                val(value, valueColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 원문: 카드 끝까지
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken ?? "\(label), \(value)"))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800) // 15px 400 #3A4150
    }

    private func val(_ s: String, _ c: Color) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(c) // 15px 600
    }

    // 4. 직접 연락 행
    private var contactRow: some View {
        PumCard {
            Button(action: onContactWorkplace) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text("사업장에 직접 연락").pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text("사장님에게 새 초대를 받아주세요").pumText(.caption).foregroundStyle(PumColor.textSecondary)
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

    // 5. 하단 주 버튼
    private var actions: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: state.requestTitle, kind: .primary, isLoading: lock.isSending, loadingTitle: "요청을 보내는 중", action: request)
            Text(state.requestNote).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s4)
        .background(PumColor.bgApp)
    }

    private func request() {
        guard lock.begin() else { return }
        onRequestAgain { ok in lock.finish(success: ok) }
    }
}

#Preview("15f") { InviteExpiredView(state: .sample) }
#Preview("15f · 큰 글자") { InviteExpiredView(state: .sample).dynamicTypeSize(.xxxLarge) }
