// UI-IOS-20h · REQ-007 · REQ-074 — 명세서 보내기. 탭 바 없음.
// 앱 직원은 앱 알림, 앱 없는 직원은 알림톡(안 되면 문자) + PDF. 보내기는 한 번만 — 처리 중은 이 버튼에만, 성공 뒤엔 잠근 채.
import SwiftUI

struct PayslipSendDirectView: View {
    var state: PayslipSendDirectState = .sample
    var onBack: () -> Void = {}
    /// 「명세서 N건 보내기」 — 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패.
    var onSend: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }
    /// 「공유」 — 앱 없는 직원 PDF
    var onSharePDF: (_ id: String) -> Void = { _ in }

    @State private var lock = PayslipSendDirectLock()
    @ScaledMetric(relativeTo: .body) private var avatarSize = PumLayout.avatar - PumTokens.Space.s2 // 원문 34

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    titleBlock
                    recipientCard
                    ForEach(state.pdfRecipients) { pdfCard($0) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
            bottomBar
        }
        .background(PumColor.bgApp)
    }

    // MARK: 위

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s8) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text("급여").pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("급여"))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.monthText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 26px 700 → 24px 근사
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // MARK: 받는 직원 카드

    private var recipientCard: some View {
        PumCard {
            HStack {
                Text(state.countText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 15px 700
                Spacer(minLength: PumTokens.Space.s8)
                Text("실지급액").pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.top, PumTokens.Space.s14)
            .padding(.bottom, PumTokens.Space.s4)
            .accessibilityHidden(true) // 행마다 읽기 문구가 있다
            ForEach(Array(state.recipients.enumerated()), id: \.element.id) { index, person in
                if index > 0 { divider }
                row(person)
            }
        }
    }

    private func row(_ person: PayslipSendDirectState.Recipient) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                avatar(person)
                texts(person)
                Text(person.amountText).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            // 넘치면 금액이 아래로
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                avatar(person)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    texts(person)
                    Text(person.amountText).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(person.spokenText))
    }

    private func avatar(_ person: PayslipSendDirectState.Recipient) -> some View {
        Text(person.initial).pumText(.footnote, weight: .bold).foregroundStyle(PumTokens.ColorToken.gray800) // 원문 #3A4150
            .frame(width: avatarSize, height: avatarSize)
            .background(PumColor.surfaceFill, in: Circle())
            .accessibilityHidden(true)
    }

    private func texts(_ person: PayslipSendDirectState.Recipient) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(person.name).pumText(.callout).foregroundStyle(PumColor.textPrimary)
            Text(person.methodText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: PDF 카드

    private func pdfCard(_ person: PayslipSendDirectState.Recipient) -> some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(person.pdfTitle).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                    Text("직접 보내거나 출력할 때").pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                shareChip(person)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12)
        }
    }

    /// 보이는 모양은 원문 칩(padding 7 11 · 모서리 9), 누름 영역만 배경 뒤에서 44pt
    private func shareChip(_ person: PayslipSendDirectState.Recipient) -> some View {
        Button { onSharePDF(person.id) } label: {
            Text("공유").pumText(.caption, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Space.s10)
                .padding(.vertical, PumTokens.Space.s6)
                .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                // 누름 영역만 44 이상으로 키우고, 배치에는 원문 칩 크기만 쓴다(카드 높이가 늘지 않게)
                .padding(.vertical, PumTokens.Space.s12)
                .padding(.horizontal, PumTokens.Space.s4)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s12)
                .padding(.horizontal, -PumTokens.Space.s4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(person.pdfSpoken))
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }

    // MARK: 하단

    private var bottomBar: some View {
        VStack(spacing: PumTokens.Space.s8) {
            Button(action: send) {
                Group {
                    if lock.isSending {
                        HStack(spacing: PumTokens.Space.s8) {
                            ProgressView().tint(.white)
                            Text("보내는 중")
                        }
                    } else {
                        Text(state.sendTitle)
                    }
                }
                .pumText(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: PumTokens.Size.buttonH) // 원문 54
                .background(PumColor.accent, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(lock.isLocked)
            .accessibilityLabel(Text(state.sendTitle))
            .accessibilityValue(lock.isSending ? Text("보내는 중") : lock.isSent ? Text("보냈어요") : Text(""))
            Text("보낸 시각 \u{00B7} 받는 방법은 활동 기록에 남아요")
                .pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s12) // 원문 34는 홈 표시 막대 자리 — 안전 영역이 대신한다
    }

    /// 한 번만 — 누르는 즉시 잠그고, 성공이면 잠근 채 둔다
    private func send() {
        guard lock.beginSend() else { return }
        onSend { success in lock.finishSend(success: success) }
    }
}

#Preview("20h") { PayslipSendDirectView(state: .sample) }
#Preview("20h · 큰 글자") { PayslipSendDirectView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("20h · 앱 없는 직원 없음") { PayslipSendDirectView(state: .allApp) }
