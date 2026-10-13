// UI-IOS-19g · REQ-073 — 직원 · 내 연차 (하위 화면, 탭 바 없음)
// 대상 아님(주 15시간 미만 · 5인 미만) 상태는 원문이 없어 이 화면에 없다.
import SwiftUI

struct MyLeaveView: View {
    let state: MyLeaveState
    var onBack: () -> Void
    var onRequestLeave: () -> Void

    init(state: MyLeaveState = .sample,
         onBack: @escaping () -> Void = {},
         onRequestLeave: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onRequestLeave = onRequestLeave
    }

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    heading
                    summaryCard
                    section(MyLeaveState.accrualHeader, rows: state.accrualRows)
                    section(MyLeaveState.usedHeader, rows: state.usedRows)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(MyLeaveState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(MyLeaveState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.subtitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(MyLeaveState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, PumTokens.Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    // MARK: 남은 연차 카드

    private var summaryCard: some View {
        let title = Text(MyLeaveState.remainingTitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
        let perDay = Text(state.perDayText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        let used = Text(state.usedText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        let earned = Text(state.earnedText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        return PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                twoColumns(title, perDay)
                Text(state.remainingText).pumText(.hero).foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                bar
                twoColumns(used, earned)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.summarySpoken))
        }
    }

    /// 좌우 두 칸 — 넘치면 세로로
    private func twoColumns<L: View, R: View>(_ left: L, _ right: R) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                left
                Spacer(minLength: 0)
                right.multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { left; right }
        }
    }

    /// 쓴 몫(회색) + 남은 몫(파랑) — 몫은 서버 값
    private var bar: some View {
        GeometryReader { geo in
            let used = geo.size.width * CGFloat(state.usedPermille) / 1000
            HStack(spacing: 0) {
                Rectangle().fill(PumTokens.ColorToken.gray500).frame(width: used)
                Rectangle().fill(PumColor.accent)
            }
            .clipShape(Capsule())
        }
        .frame(height: PumTokens.Space.s8)
        .accessibilityHidden(true)
    }

    // MARK: 섹션

    private func section(_ header: String, rows: [MyLeaveRow]) -> some View {
        PumCard {
            Text(header).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Size.rowPadY)
                .padding(.bottom, PumTokens.Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 { divider }
                rowView(row)
            }
        }
    }

    private func rowView(_ r: MyLeaveRow) -> some View {
        let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(r.title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            if let detail = r.detail {
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        let value = Text(r.value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                texts
                Spacer(minLength: 0)
                value.multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { texts; value }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(r.spoken))
    }

    // MARK: 하단

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s12) {
            PumButton(title: MyLeaveState.requestTitle, action: onRequestLeave)
            Text(MyLeaveState.footerNotice)
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("19g 원문") { MyLeaveView(state: .sample) }
#Preview("19g · 큰 글자") { MyLeaveView(state: .sample).dynamicTypeSize(.xxxLarge) }
