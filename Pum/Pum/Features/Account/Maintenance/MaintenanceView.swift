// UI-IOS-6w · REQ-029 · REQ-094 — 점검 중. 탭 바 · 머리 없음.
// 하단 버튼(퇴근하기/출근하기)은 절대 잠그지 않는다 — PumButton isLoading을 넘기지 않고, 중복 탭은 호출자가 한 번만 처리한다(REQ-029).
import SwiftUI

struct MaintenanceView: View {
    let state: MaintenanceState
    var onClockOut: () -> Void
    var onClockIn: () -> Void

    /// 회색 원 지름 — 6t와 같은 값(원문 약 24)
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    private let checkRatio: CGFloat = 0.45

    init(state: MaintenanceState = .sample,
         onClockOut: @escaping () -> Void = {},
         onClockIn: @escaping () -> Void = {}) {
        self.state = state
        self.onClockOut = onClockOut
        self.onClockIn = onClockIn
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    Text(MaintenanceState.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(state.schedule).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                rowsCard
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

    private var rowsCard: some View {
        PumCard {
            ForEach(Array(state.rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 원문: 카드 끝에서 끝까지
                }
                rowView(row)
            }
        }
    }

    private func rowView(_ row: MaintenanceRow) -> some View {
        HStack(alignment: .top, spacing: PumTokens.Space.s12) {
            Circle().fill(PumColor.surfaceFill)
                .overlay {
                    Image(systemName: row.symbol)
                        .font(.system(size: circleSize * checkRatio, weight: .bold))
                        .foregroundStyle(row.paused ? PumColor.textSecondary : PumColor.textPrimary)
                }
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(row.title).pumText(.body, weight: .semibold)
                    .foregroundStyle(row.paused ? PumColor.textSecondary : PumColor.textPrimary)
                Text(row.message).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.spoken))
    }

    private func workingCard(_ working: MaintenanceWorking) -> some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(working.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(working.message).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(working.title). \(working.message)"))
    }

    @ViewBuilder private var bottomBar: some View {
        if let action = state.action {
            VStack(spacing: PumTokens.Space.s8) {
                // 원문: 먹색 버튼. isLoading을 넘기지 않는다(잠김 금지)
                PumButton(title: action.title, kind: .dark, action: action.kind == .clockOut ? onClockOut : onClockIn)
                Text(action.caption).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
        }
    }
}

#Preview("6w") { MaintenanceView() }
#Preview("6w · 큰 글자") { MaintenanceView().dynamicTypeSize(.xxxLarge) }
