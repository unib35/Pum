// UI-IOS-1ao · REQ-026 · REQ-029 · DEC-005 — 조기 퇴근: 예정보다 일찍 퇴근 버튼을 누르면 사유만 묻고 기록한다.
// 사유를 고르지 않아도 기록할 수 있다(REQ-029). 막을 눌러도 「계속 근무」와 같이 닫는다.
import SwiftUI

struct EarlyLeaveView: View {
    @State private var state: EarlyLeaveState
    @State private var sheetOpen: Bool
    var onContinue: () -> Void
    /// 선택한 사유(없으면 nil)를 넘긴다
    var onRecord: (EarlyLeaveReason?) -> Void

    init(state: EarlyLeaveState = .sample, sheetOpen: Bool = true,
         onContinue: @escaping () -> Void = {},
         onRecord: @escaping (EarlyLeaveReason?) -> Void = { _ in }) {
        _state = State(initialValue: state)
        _sheetOpen = State(initialValue: sheetOpen)
        self.onContinue = onContinue
        self.onRecord = onRecord
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: $sheetOpen, onDismiss: onContinue) {
                EarlyLeaveSheet(
                    state: state,
                    onSelect: { state.selected = $0 },
                    onContinue: { sheetOpen = false; onContinue() },
                    onRecord: { sheetOpen = false; onRecord(state.recordedReason) }
                )
            }
    }

    /// 뒤 화면: 사업장 칩 + 근무 중 카드(1av를 단순하게)
    private var background: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            HStack {
                PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
                Spacer()
            }
            workingCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var workingCard: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            HStack(spacing: PumTokens.Space.s8) {
                Circle().fill(PumColor.statusDone).frame(width: PumTokens.Space.s8, height: PumTokens.Space.s8) // 원문 점 약 8
                Text("근무 중").pumText(.callout, weight: .semibold)
                    .foregroundStyle(.white.opacity(EarlyLeaveLocal.cardTextOpacity))
            }
            elapsed
            // 원문: 큰 시간 아래 한 줄 — 왼쪽 「출근」, 오른쪽 「퇴근 예정」(좁으면 세로)
            ViewThatFits(in: .horizontal) {
                HStack { clockIn; Spacer(minLength: PumTokens.Space.s8); plannedEnd }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) { clockIn; plannedEnd }
            }
            .pumText(.footnote).foregroundStyle(.white.opacity(EarlyLeaveLocal.cardTextOpacity))
        }
        .padding(PumTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var elapsed: some View {
        let p = WorkingFormat.parts(state.elapsedMinutes)
        return Text("\(p.hours):\(String(format: "%02d", p.minutes))")
            .pumText(.display).foregroundStyle(.white)
            .accessibilityLabel(Text(WorkingFormat.elapsedLabel(state.elapsedMinutes)))
    }

    private var clockIn: some View { Text("\(EarlyLeaveFormat.clock(state.clockInMinute)) 출근") }
    private var plannedEnd: some View { Text("\(EarlyLeaveFormat.clock(state.plannedEndMinute)) 퇴근 예정") }
}

#Preview("1ao") { EarlyLeaveView() }
#Preview("1ao · 큰 글자") { EarlyLeaveView().dynamicTypeSize(.accessibility1) }
#Preview("1ao · 사유 미선택") {
    var s = EarlyLeaveState.sample
    s.selected = nil
    return EarlyLeaveView(state: s)
}
