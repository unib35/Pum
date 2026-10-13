// UI-IOS-7a · REQ-076 — 사장님 월급날 지급 체크리스트(확정). 탭 바 없음. 돈을 보내지 않는다 — 은행 앱에서 보낸 뒤 체크 · 기록만 돕는다.
// 버튼은 클로저로만(onBack · onSend · onOpenPaid). 「보내기 ›」와 행 전체는 지급 시트(7b)를 여는 같은 클로저. 시트는 다음 작업.
import SwiftUI

struct PaymentChecklistView: View {
    var state: PaymentChecklistState = .sample
    var onBack: () -> Void = {}
    var onSend: (String) -> Void = { _ in }       // 지급 대기 행 · 보내기 › — 직원 ID
    var onOpenPaid: (String) -> Void = { _ in }   // 지급 완료 행 — 직원 ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var barHeight = PumTokens.Space.s8 // 원문 진행 막대 높이 약 8pt
    @ScaledMetric private var checkSize = PumLayout.avatar - PumTokens.Space.s12 // 원문 체크 원 약 24pt

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    summaryCard
                    if !state.pending.isEmpty { pendingSection }
                    if !state.paid.isEmpty { paidSection }
                    Text(PaymentChecklistState.footnote)
                        .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
                .padding(.bottom, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
    }

    // 2. 요약 카드
    private var summaryCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                        Text(state.payDateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                        Spacer(minLength: PumTokens.Space.s8)
                        PumBadge(text: state.statusBadgeText, kind: .active)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        PumBadge(text: state.statusBadgeText, kind: .active)
                        Text(state.payDateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .lastTextBaseline) {
                        total
                        Spacer(minLength: PumTokens.Space.s8)
                        count
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        total
                        count
                    }
                }
                .padding(.top, PumTokens.Space.s8) // 원문 금액 줄 위 8
                bar.padding(.top, PumTokens.Space.s14) // 원문 막대 위 14
                ViewThatFits(in: .horizontal) {
                    HStack {
                        paidSummary
                        Spacer(minLength: PumTokens.Space.s8)
                        remainingSummary
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        paidSummary
                        remainingSummary
                    }
                }
                .padding(.top, PumTokens.Space.s8) // 원문 요약 줄 위 8
            }
            .padding(.vertical, PumTokens.Space.s16)
            .padding(.horizontal, PumTokens.Space.s18) // 원문 padding 16 18
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.summaryAccessibilityText))
    }

    // 원문 30px 700 → 토큰 단계 hero 32px 근사(1u와 같은 값)
    private var total: some View {
        Text(state.totalText).pumText(.hero).foregroundStyle(PumColor.textPrimary)
            .lineLimit(1).minimumScaleFactor(0.5)
    }
    private var count: some View {
        Text(state.employeeCountText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }
    private var paidSummary: some View {
        Text(state.paidSummaryText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
            .fixedSize(horizontal: false, vertical: true)
    }
    private var remainingSummary: some View {
        Text(state.remainingSummaryText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PumColor.surfaceFill)
                Capsule().fill(PumColor.statusDone)
                    .frame(width: geo.size.width * state.progress)
                    .animation(PumMotion.respecting(reduceMotion, PumMotion.progress), value: state.progress) // M22
            }
        }
        .frame(height: barHeight)
    }

    // 3. 지급 대기
    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: state.pendingHeaderText).padding(.top, PumTokens.Space.s2) // 원문 padding 2 4 0
            PumCard {
                ForEach(Array(state.pending.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { divider }
                    row(p)
                }
            }
        }
    }

    // 4. 지급 완료
    private var paidSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: state.paidHeaderText).padding(.top, PumTokens.Space.s2)
            PumCard {
                ForEach(Array(state.paid.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { divider }
                    row(p)
                }
            }
        }
    }

    private func row(_ p: PaymentChecklistPerson) -> some View {
        Button { p.isPaid ? onOpenPaid(p.id) : onSend(p.id) } label: {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                checkCircle(paid: p.isPaid)
                    .frame(height: PumLayout.avatar) // 아바타 줄에 맞춰 세로 중앙
                PumAvatar(name: p.name, colorIndex: p.colorIndex)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    // 큰 글자에서 금액 · 계좌는 이름 아래로 쌓는다
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                            nameText(p)
                            Spacer(minLength: PumTokens.Space.s8)
                            amountText(p)
                        }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            nameText(p)
                            amountText(p)
                        }
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                            accountText(p)
                            Spacer(minLength: PumTokens.Space.s8)
                            trailingNote(p)
                        }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            accountText(p)
                            trailingNote(p)
                        }
                    }
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(p.accessibilityText))
        .accessibilityAddTraits(.isButton)
    }

    private func nameText(_ p: PaymentChecklistPerson) -> some View {
        Text(p.name).pumText(.body, weight: .semibold)
            .foregroundStyle(p.isPaid ? PumTokens.ColorToken.gray700 : PumColor.textPrimary) // 완료 행 이름 회색(원문 rgb 91,97,112)
            .fixedSize(horizontal: false, vertical: true)
    }
    private func amountText(_ p: PaymentChecklistPerson) -> some View {
        Text(p.amountText).pumText(.headline, weight: .bold) // 원문 16px 700 → headline 17px 근사
            .foregroundStyle(p.isPaid ? PumColor.textTertiary : PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
    private func accountText(_ p: PaymentChecklistPerson) -> some View {
        Text(p.accountText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    @ViewBuilder private func trailingNote(_ p: PaymentChecklistPerson) -> some View {
        if let done = p.processedText {
            Text(done).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
        } else {
            Text("보내기 ›").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
        }
    }

    // 공통 후보: 체크 원(대기 = 빈 원 · 완료 = 회색 원 + 먹색 체크). OwnerHomeUnverified의 상태 원과 같은 값.
    private func checkCircle(paid: Bool) -> some View {
        Circle()
            .fill(paid ? PumColor.surfaceFill : PumColor.surfaceCard)
            .overlay {
                if paid {
                    Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(PumColor.textPrimary)
                } else {
                    Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: 1.5)
                }
            }
            .frame(width: checkSize, height: checkSize)
            .accessibilityHidden(true)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }
}

#Preview("7a") { PaymentChecklistView(state: .sample) }
#Preview("7a · 큰 글자") { PaymentChecklistView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("7a · 대기 없음") {
    PaymentChecklistView(state: { var s = PaymentChecklistState.sample; s.pending = []; return s }())
}
#Preview("7a · 완료 없음") {
    PaymentChecklistView(state: { var s = PaymentChecklistState.sample; s.paid = []; return s }())
}
