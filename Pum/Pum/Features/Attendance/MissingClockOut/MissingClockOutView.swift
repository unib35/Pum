// UI-IOS-1al · REQ-025 · DEC-004 — 퇴근 미확정: 예정 퇴근 후 6시간 무응답이면 세션만 종료(급여 미반영).
// 다음날 아침 직원이 실제 시간 + 사유를 보내면 사장님이 확인한다. 막을 누르면 시트만 닫고, 뒤 카드를 누르면 다시 열린다.
import SwiftUI

struct MissingClockOutView: View {
    @State private var state: MissingClockOutState
    @State private var sheetOpen: Bool
    var onSelectTimeField: (MissingClockOutField) -> Void
    var onRequest: (_ inputMinute: Int, _ reason: MissingClockOutReason) -> Void

    init(state: MissingClockOutState = .initial, sheetOpen: Bool = true,
         onSelectTimeField: @escaping (MissingClockOutField) -> Void = { _ in },
         onRequest: @escaping (Int, MissingClockOutReason) -> Void = { _, _ in }) {
        _state = State(initialValue: state)
        _sheetOpen = State(initialValue: sheetOpen)
        self.onSelectTimeField = onSelectTimeField
        self.onRequest = onRequest
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: $sheetOpen) {
                MissingClockOutSheet(
                    state: state,
                    onSelectField: { state.selectedField = $0; onSelectTimeField($0) }, // 시 · 분 입력 휠은 후속
                    onStep: { state.step($0, by: $1) },
                    onSelect: { state.selected = $0 },
                    onRequest: {
                        guard let reason = state.selected else { return }
                        sheetOpen = false
                        onRequest(state.inputMinute, reason)
                    }
                )
            }
    }

    private var background: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            HStack {
                PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial) {}
                Spacer()
            }
            .padding(.top, PumTokens.Space.s8)
            Button { sheetOpen = true } label: { card }
                .buttonStyle(.plain)
                .accessibilityHint(Text(sheetOpen ? "" : "실제 퇴근시간 입력창을 엽니다"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var card: some View {
        PumCard(attention: true) { // 주황 테두리 — 1j 강조 행과 같은 방식
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                HStack(spacing: PumTokens.Space.s8) {
                    PumBadge(text: "퇴근 미확정", kind: .attention)
                    Text(state.dateText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                }
                // 목업 약 20px 700 → title3
                Text("어제 퇴근 기록이 없어요.\n실제 퇴근시간을 알려주세요")
                    .pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                times
                notice
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var times: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) { timeCells }
            VStack(spacing: PumTokens.Space.s8) { timeCells }
        }
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var timeCells: some View {
        timeCell("출근", state.clockInText, warn: false)
        timeCell("예정 퇴근", state.plannedEndText, warn: false)
        timeCell("퇴근", "기록 없음", warn: true)
    }

    private func timeCell(_ label: String, _ value: String, warn: Bool) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2).foregroundStyle(warn ? PumColor.statusAttention : PumColor.textSecondary)
            Text(value).pumText(.body, weight: .semibold).foregroundStyle(warn ? PumColor.statusAttention : PumColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s12)
    }

    private var notice: some View {
        (Text(state.noticeLead)
            + Text(state.noticeStrong).fontWeight(.bold)
            + Text(MissingClockOutState.noticeTail))
            .pumText(.caption)
            .foregroundStyle(PumColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("1al") { MissingClockOutView() }
#Preview("1al · 캡처 상태") { MissingClockOutView(state: .sample) }
#Preview("1al · 큰 글자") { MissingClockOutView(state: .sample).dynamicTypeSize(.accessibility1) }
