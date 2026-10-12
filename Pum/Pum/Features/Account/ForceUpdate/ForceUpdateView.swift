// UI-IOS-6t · REQ-029 · REQ-094 — 업데이트 필수. 탭 바 · 머리 없음(뒤로 갈 수 없음).
// 「퇴근만 기록」은 절대 잠그지 않는다 — 공통 PumButton의 처리 중 표시는 버튼을 잠그므로 쓰지 않고, 중복 탭은 호출자가 한 번만 처리한다(REQ-029). 앱 스토어 이동은 호출자가 한다.
import SwiftUI

struct ForceUpdateView: View {
    let state: ForceUpdateState
    var onUpdate: () -> Void
    var onClockOutOnly: () -> Void

    /// 회색 원 지름 — 21l과 같은 값(원문 약 24)
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    private let checkRatio: CGFloat = 0.45

    init(state: ForceUpdateState = .sample,
         onUpdate: @escaping () -> Void = {},
         onClockOutOnly: @escaping () -> Void = {}) {
        self.state = state
        self.onUpdate = onUpdate
        self.onClockOutOnly = onClockOutOnly
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    Text(ForceUpdateState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(state.message).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                versionCard
                if let working = state.working { workingCard(working) }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s24)
            .padding(.bottom, PumTokens.Space.s8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    private var versionCard: some View {
        PumCard {
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.horizontal, PumTokens.Size.rowPadX)
                }
                infoRow(row)
            }
        }
    }

    private func infoRow(_ row: ForceUpdateRow) -> some View {
        let label = Text(row.label).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let value = Text(row.value).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                label
                Spacer(minLength: 0)
                value.fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                label
                value.multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.spoken))
    }

    private func workingCard(_ working: ForceUpdateWorking) -> some View {
        PumCard {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                Circle().fill(PumColor.surfaceFill)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: circleSize * checkRatio, weight: .bold))
                            .foregroundStyle(PumColor.textPrimary)
                    }
                    .frame(width: circleSize, height: circleSize)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(working.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(working.message).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(working.title). \(working.message)"))
    }

    private var bottomBar: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: ForceUpdateState.updateTitle, kind: .primary, action: onUpdate)
            if state.showsClockOut {
                // 원문: 흰 바탕 · 옅은 테두리 → outline. 처리 중 표시(isLoading)를 넘기면 버튼이 잠기므로 넘기지 않는다
                PumButton(title: ForceUpdateState.clockOutTitle, kind: .outline, action: onClockOutOnly)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("6t") { ForceUpdateView() }
#Preview("6t · 근무 아님") { ForceUpdateView(state: .notWorking) }
#Preview("6t · 큰 글자") { ForceUpdateView().dynamicTypeSize(.xxxLarge) }
