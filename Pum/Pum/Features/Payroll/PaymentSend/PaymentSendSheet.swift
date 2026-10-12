// UI-IOS-7b · 21e · 21f · REQ-077 · DEC-002 — 직원별 지급 시트(내용). 가림(21e) ↔ 보임(7b)은 Face ID(21f)로만 바뀐다.
// 돈을 보내지 않는다 — 계좌번호 · 금액 복사와 「지급 완료 처리」 클로저만. 일괄 복사 버튼은 없다(DEC-002).
// 색: 파랑 = 주 버튼 · 「Face ID로 보기」, 초록 = 복사됨, 회색 = 보조. 복사 확인은 M9(1.5초), Reduce Motion 존중.
import SwiftUI

struct PaymentSendSheet: View {
    let model: PaymentSendModel
    /// Face ID + 서버 조회는 부모가 한다. 전체 번호를 done으로 넘기고, 실패 · 취소면 nil. 연결 전 기본값은 nil(가린 채).
    var onReveal: (_ done: @escaping (String?) -> Void) -> Void = { done in done(nil) }
    var onMarkPaid: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var avatarSize = PumLayout.avatar + PumTokens.Space.s8 // 원문 약 44pt

    private var state: PaymentSendState { model.state }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            header
            card
            if !model.isRevealed {
                Text(state.bankLineText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center) // 21e: 카드 아래 가운데
                    .multilineTextAlignment(.center)
            }
            if let toast = model.toastMessage {
                PumToast(message: toast, systemImage: "checkmark")
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
            PumButton(title: PaymentSendState.markPaidTitle, kind: .primary, action: onMarkPaid)
                .disabled(!model.canMarkPaid)
                .accessibilityHint(Text(model.canMarkPaid ? "" : "Face ID로 계좌번호를 확인한 뒤 누를 수 있어요")) // 빈 힌트는 읽지 않음
            if model.isRevealed {
                Text(PaymentSendState.clipboardNotice).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s8)
        .animation(PumMotion.respecting(reduceMotion, PumMotion.base), value: model.toastMessage)
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: model.isRevealed) // M27
        .onChange(of: model.toastMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
        .onChange(of: model.amountCopied) { _, copied in
            if copied { AccessibilityNotification.Announcement("지급액을 복사했어요").post() }
        }
    }

    // MARK: 머리

    private var header: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: state.name, colorIndex: state.colorIndex, size: avatarSize)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.titleText).pumText(.title3).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(state.subtitleText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Space.s4)
    }

    // MARK: 카드

    private var card: some View {
        PumCard {
            accountRow
            amountRow
        }
    }

    private var accountRow: some View {
        fieldRow(label: "계좌번호", isLast: false) {
            if let full = model.fullAccount {
                valueText(full, spoken: "계좌번호, \(PaymentSendState.spokenAccount(full))")
                Text(state.bankLineText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            } else {
                valueText(state.maskedAccount, spoken: state.maskedAccessibilityText)
            }
        } trailing: {
            if model.isRevealed {
                copyControl(title: "복사", copied: model.accountCopied, style: .outline, spoken: "계좌번호", action: model.copyAccount)
            } else {
                PumChipButton(title: "Face ID로 보기", kind: .accent) { model.reveal(using: onReveal) }
                    .disabled(model.isRevealBusy) // 한 번만
                    .accessibilityLabel(Text("Face ID로 계좌번호 보기"))
            }
        }
    }

    private var amountRow: some View {
        fieldRow(label: "지급액", isLast: true) {
            valueText(state.amountText, spoken: "지급액, \(state.amountText)")
            if model.isRevealed {
                Text("명세서 실지급액과 같아요").pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
        } trailing: {
            copyControl(title: "복사", copied: model.amountCopied, style: model.isRevealed ? .outline : .chip,
                        spoken: "지급액", action: model.copyAmount)
        }
    }

    private func valueText(_ s: String, spoken: String? = nil) -> some View {
        Text(s).pumText(.title3).foregroundStyle(PumColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(spoken ?? s))
    }

    /// 라벨 · 값 줄 · (오른쪽) 버튼. 넓으면 한 줄, 좁으면(큰 글자) 버튼이 아래로. 공통 후보: 값 + 복사 행.
    private func fieldRow<V: View, T: View>(label: String, isLast: Bool,
                                           @ViewBuilder values: () -> V, @ViewBuilder trailing: () -> T) -> some View {
        let revealed = model.isRevealed
        let labelView = Text(label)
            .pumText(revealed ? .caption : .callout, weight: revealed ? .regular : .semibold) // 7b: 12 회색 / 21e: 14 먹색
            .foregroundStyle(revealed ? PumColor.textSecondary : PumColor.textPrimary)
            .accessibilityHidden(true) // 값 쪽 읽기 문구에 라벨을 넣는다
        let valueBlock = VStack(alignment: .leading, spacing: PumTokens.Space.s2) { labelView; values() }
        let button = trailing()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                valueBlock.frame(maxWidth: .infinity, alignment: .leading)
                button.fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                valueBlock.frame(maxWidth: .infinity, alignment: .leading)
                button.fixedSize()
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
    }

    // MARK: 복사 버튼

    private enum CopyStyle { case outline, chip }

    /// 7b: 테두리 버튼 ↔ 연초록 「✓ 복사됨」 · 21e 금액: 회색 알약 ↔ 연초록 알약. M9: 1.5초 뒤 되돌아간다.
    @ViewBuilder
    private func copyControl(title: String, copied: Bool, style: CopyStyle, spoken: String, action: @escaping () -> Void) -> some View {
        Group {
            if copied {
                Button(action: action) {
                    HStack(spacing: PumTokens.Space.s6) {
                        Image(systemName: "checkmark").font(.footnote.weight(.bold)).accessibilityHidden(true)
                        Text("복사됨")
                    }
                    .pumText(style == .outline ? .callout : .caption, weight: style == .outline ? .semibold : .bold)
                    .foregroundStyle(PumColor.statusDone)
                    .padding(.horizontal, style == .outline ? PumTokens.Space.s16 : PumTokens.Space.s14)
                    .padding(.vertical, style == .outline ? PumTokens.Space.s12 : PumTokens.Space.s8)
                    .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else if style == .outline {
                PumButton(title: title, kind: .outline, size: .small, action: action)
            } else {
                PumChipButton(title: title, kind: .neutral, action: action)
            }
        }
        .accessibilityLabel(Text(copied ? "\(spoken) 복사됨" : "\(spoken) 복사"))
    }
}
