// UI-IOS-2b · REQ-001 · REQ-011 — 휴대폰 인증: 인증번호 6자리(확정). 탭 바 없음.
// 실제 입력은 숨은 TextField 하나, 6칸은 그 값을 나눠 그린다. 0초 · 오류 · 처리 중 디자인은 없다.
// 비활성 확인 버튼의 이유 문구는 디자인 없음(충돌 #30과 같은 처리: 회색 비활성만).
import SwiftUI

struct PhoneVerifyView: View {
    @State private var state: PhoneVerifyState
    var onBack: () -> Void
    var onChangeNumber: () -> Void
    var onResend: () -> Void
    var onConfirm: (String) -> Void

    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretOn = true

    /// 목업 칸 높이 약 60 — 토큰에 없어 이름을 붙임(DEC-005), 큰 글자에서 글자와 함께 커진다
    @ScaledMetric(relativeTo: .title2) private var cellHeight: CGFloat = 60
    @ScaledMetric(relativeTo: .title2) private var caretHeight: CGFloat = 28
    /// 목업 칸 사이 약 6 — space-6
    private let cellGap = PumTokens.Space.s6
    /// 목업 현재 칸 파랑 테두리 2 — 토큰에 없어 이름을 붙임(공통 후보: 입력 칸 포커스 테두리)
    private let activeBorder: CGFloat = 2

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
        .task { await countdown() }
        .task(id: reduceMotion) { await blink() }
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
                .padding(.vertical, PumTokens.Space.s12)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s12)
        }
        .buttonStyle(.plain)
    }

    // 3. 6칸
    private var codeField: some View {
        HStack(spacing: cellGap) {
            ForEach(0..<PhoneVerifyState.codeLength, id: \.self) { i in cell(i) }
        }
        .overlay { hiddenInput }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.accessibilityCodeText))
        .accessibilityHint(Text("두 번 탭하면 입력해요"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { focused = true }
    }

    private func cell(_ i: Int) -> some View {
        let isActive = focused && state.activeIndex == i
        let radius = PumTokens.Radius.lg
        return ZStack {
            // 숫자 26px 700 → title2(24px 700) 근사(26 단계 없음)
            Text(state.digit(at: i) ?? "")
                .pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.5)
            if isActive {
                Rectangle().fill(PumColor.accent)
                    .frame(width: activeBorder, height: caretHeight)
                    .opacity(caretOn ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: cellHeight) // 한 줄 6칸 유지: 폭은 나눠 갖고 높이만 커진다
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(isActive ? PumColor.accent : PumColor.borderHairline,
                              lineWidth: isActive ? activeBorder : 1)
        }
    }

    private var hiddenInput: some View {
        TextField("", text: Binding(
            get: { state.code },
            set: { state.code = PhoneVerifyState.sanitized($0) }
        ))
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)
        .focused($focused)
        .foregroundStyle(.clear) // 입력한 숫자가 첫 칸 뒤로 비치지 않게
        .tint(.clear)
        .opacity(0.011) // 눈에는 안 보이고 입력만 받는다
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    // 4. 남은 시간 · 다시 보내기
    private var timerRow: some View {
        HStack(alignment: .center) {
            Text(state.remainingText).pumText(.footnote) // 13px 400
                .foregroundStyle(PumColor.textSecondary)
                .padding(.leading, PumTokens.Space.s8) // 목업: 칸 왼쪽보다 약 4 안쪽 → 가까운 단계
                .monospacedDigit()
            Spacer(minLength: PumTokens.Space.s8)
            Button(action: onResend) {
                Text("다시 보내기").pumText(.footnote, weight: .semibold) // 13px 600
                    .foregroundStyle(PumColor.accent)
                    .padding(.horizontal, PumTokens.Space.s8)
                    .padding(.vertical, PumTokens.Space.s12) // 누름 영역만 44 쪽으로 넓힌다
                    .contentShape(Rectangle())
                    .padding(.vertical, -PumTokens.Space.s12)
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

    // 남은 초를 1초마다 줄이고 0이면 멈춘다
    private func countdown() async {
        while !Task.isCancelled && state.remainingSeconds > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            state.tick()
        }
    }

    // 커서 깜박임(동작 줄이기면 고정)
    private func blink() async {
        caretOn = true
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(530))
            if Task.isCancelled { return }
            caretOn.toggle()
        }
    }
}

#Preview("2b") { PhoneVerifyView(state: .sample) }
#Preview("2b · 큰 글자") { PhoneVerifyView(state: .sample).dynamicTypeSize(.xxxLarge) }
