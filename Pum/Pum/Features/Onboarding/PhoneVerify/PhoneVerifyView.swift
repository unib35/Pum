// UI-IOS-2b · REQ-001 · REQ-011 — 휴대폰 인증: 인증번호 6자리(확정). 탭 바 없음.
// 6칸은 공통 PumCodeField. 0초 · 오류 · 처리 중 디자인은 없다.
// 비활성 확인 버튼의 이유 문구는 디자인 없음(충돌 #30과 같은 처리: 회색 비활성만).
import SwiftUI

struct PhoneVerifyView: View {
    @State private var state: PhoneVerifyState
    var onBack: () -> Void
    var onChangeNumber: () -> Void
    var onResend: () -> Void
    var onConfirm: (String) -> Void

    @FocusState private var focused: Bool
    /// 다시 보내기마다 바뀌어 카운트다운을 새로 시작한다
    @State private var countdownRun = 0

    init(state: PhoneVerifyState = .sample,
         onBack: @escaping () -> Void = {},
         onChangeNumber: @escaping () -> Void = {},
         onResend: @escaping () -> Void = {},
         onConfirm: @escaping (String) -> Void = { _ in }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onChangeNumber = onChangeNumber
        self.onResend = onResend
        self.onConfirm = onConfirm
    }

    var body: some View {
        ScrollView {
            // 원문 간격: 뒤로 → 제목 약 20, 안내 → 6칸 · 6칸 → 남은 시간 약 16
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                HStack {
                    PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
                    Spacer()
                }
                .padding(.bottom, PumTokens.Space.s4)
                heading
                codeField
                timerRow
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollDismissesKeyboard(.never)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .task { focused = true }
        .task(id: countdownRun) { await countdown() }
    }

    // 2. 큰 제목 + 안내
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("인증번호 6자리를\n입력해주세요")
                .pumText(.title1) // 목업 약 28px 700 = title1
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            // 번호 변경 버튼이 문장 끝에 이어 붙고, 큰 글자에서는 아래 줄로 내려간다
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) { leadText; changeButton }
                VStack(alignment: .leading, spacing: 0) { leadText; changeButton }
            }
        }
    }

    private var leadText: some View {
        Text(state.subtitleLead).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
    }

    private var changeButton: some View {
        Button(action: onChangeNumber) {
            Text("번호 변경").pumText(.callout).foregroundStyle(PumColor.accent) // 14px 600
                // 보이는 줄 높이는 그대로, 누름 영역만 위아래로 넓힌다(줄 간격이 원문보다 벌어지지 않게)
                .padding(.vertical, PumTokens.Space.s14) // 줄 높이 약 19 + 28 ≥ 44
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s14)
        }
        .buttonStyle(.plain)
    }

    // 3. 6칸 — 공통 PumCodeField
    private var codeField: some View {
        PumCodeField(code: Binding(get: { state.code }, set: { state.code = $0 }),
                     length: PhoneVerifyState.codeLength, characters: .digits,
                     label: "인증번호", focus: $focused)
    }

    // 4. 남은 시간 · 다시 보내기
    private var timerRow: some View {
        HStack(alignment: .center) {
            Text(state.remainingText).pumText(.footnote) // 13px 400
                .foregroundStyle(PumColor.textSecondary)
                .padding(.leading, PumTokens.Space.s8) // 목업: 칸 왼쪽보다 약 4 안쪽 → 가까운 단계
                .monospacedDigit()
            Spacer(minLength: PumTokens.Space.s8)
            Button(action: resend) {
                Text("다시 보내기").pumText(.footnote, weight: .semibold) // 13px 600
                    .foregroundStyle(PumColor.accent)
                    .padding(.horizontal, PumTokens.Space.s8)
                    .padding(.vertical, PumTokens.Space.s14) // 누름 영역만 44로 넓힌다(줄 높이 약 17 + 28)
                    .contentShape(Rectangle())
                    .padding(.vertical, -PumTokens.Space.s14)
            }
            .buttonStyle(.plain)
        }
    }

    // 5. 확인(키보드 위에 붙는다)
    private var actions: some View {
        PumButton(title: "확인", kind: .primary) { onConfirm(state.code) }
            .disabled(!state.isComplete)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }

    // 만료 시각을 정해 두고 1초마다 남은 초를 다시 계산, 0이면 멈춘다
    private func countdown() async {
        let deadline = Date().addingTimeInterval(TimeInterval(state.remainingSeconds))
        while !Task.isCancelled && state.remainingSeconds > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            state.update(deadline: deadline, now: Date())
        }
    }

    private func resend() {
        state.restart()
        countdownRun += 1
        focused = true
        onResend()
    }
}

#Preview("2b") { PhoneVerifyView(state: .sample) }
#Preview("2b · 큰 글자") { PhoneVerifyView(state: .sample).dynamicTypeSize(.xxxLarge) }
