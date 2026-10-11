// UI-IOS-2d · REQ-002 — 초대 코드 입력: 코드 · 링크 · QR(확정). 탭 바 없음.
// 6칸은 공통 PumCodeField. 잘못된 코드 · 만료 · 조회 중 디자인은 없다(만들지 않음).
// 비활성 확인 버튼의 이유 문구는 디자인 없음(충돌 #30과 같은 처리: 회색 비활성만).
import SwiftUI

struct InviteCodeView: View {
    @State private var state: InviteCodeState
    /// 부모가 조회 결과를 넘기는 곳(6자리 조회 후 갱신). nil이면 카드 숨김.
    var match: InviteMatch?
    var onBack: () -> Void
    var onCodeComplete: (String) -> Void
    var onScanQR: () -> Void
    var onConfirm: (String) -> Void

    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 목업 사업장 색 네모 약 40 — 토큰에 없어 이름을 붙임(DEC-005), 큰 글자에서 글자와 함께 커진다
    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 40

    init(state: InviteCodeState = .entry,
         match: InviteMatch? = nil,
         onBack: @escaping () -> Void = {},
         onCodeComplete: @escaping (String) -> Void = { _ in },
         onScanQR: @escaping () -> Void = {},
         onConfirm: @escaping (String) -> Void = { _ in }) {
        var initial = state
        if initial.matched == nil { initial.matched = match }
        _state = State(initialValue: initial)
        self.match = match
        self.onBack = onBack
        self.onCodeComplete = onCodeComplete
        self.onScanQR = onScanQR
        self.onConfirm = onConfirm
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                HStack {
                    PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
                    Spacer()
                }
                .padding(.bottom, PumTokens.Space.s4)
                heading
                codeField
                if let m = state.visibleMatch {
                    matchCard(m)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }
                qrButton
            }
            .animation(PumMotion.respecting(reduceMotion, PumMotion.base), value: state.visibleMatch) // M22
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollDismissesKeyboard(.never)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .task {
            focused = true
            // 딥링크로 코드가 채워져 들어왔으면 바로 조회 요청
            if state.isComplete && state.matched == nil { onCodeComplete(state.code) }
        }
        .onChange(of: state.code) { _, new in
            state.matched = nil // 코드가 바뀌면 이전 매칭은 무효
            if new.count == InviteCodeState.codeLength { onCodeComplete(new) }
        }
        .onChange(of: match) { _, new in state.matched = new }
    }

    // 2. 큰 제목 + 안내
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("사장님께 받은\n초대 코드를 입력해주세요")
                .pumText(.title1) // 목업 약 28px 700 = title1
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("카카오톡 링크를 눌렀다면 자동으로 채워져요")
                .pumText(.callout, weight: .regular) // 14px 400
                .foregroundStyle(PumColor.textSecondary)
        }
    }

    // 3. 6칸 — 공통 PumCodeField
    private var codeField: some View {
        PumCodeField(code: Binding(get: { state.code }, set: { state.code = $0 }),
                     length: InviteCodeState.codeLength, characters: .alphanumeric,
                     label: "초대 코드", focus: $focused)
    }

    // 4. 매칭된 사업장 카드
    private func matchCard(_ m: InviteMatch) -> some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                Text(m.initial).pumText(.callout, weight: .bold).foregroundStyle(.white) // 14px 700
                    .frame(width: workplaceTile, height: workplaceTile)
                    .background(m.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(m.workplaceName).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
                    Text(m.subtitleText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary) // 12px 400
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(PumColor.statusDone)
            }
            .padding(PumTokens.Space.s16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(m.accessibilityText))
    }

    // 5. QR 스캔 — 텍스트 버튼
    private var qrButton: some View {
        Button(action: onScanQR) {
            HStack(spacing: PumTokens.Space.s8) {
                Image(systemName: "qrcode")
                Text("QR로 스캔하기").pumText(.body, weight: .semibold) // 15px 600
            }
            .foregroundStyle(PumColor.accent)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // 6. 초대 확인하기(키보드 위에 붙는다)
    private var actions: some View {
        PumButton(title: "초대 확인하기", kind: .primary) { onConfirm(state.code) }
            .disabled(!state.canConfirm)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }
}

#Preview("2d") { InviteCodeView(state: .sample) }
#Preview("2d · 빈 코드") { InviteCodeView() }
#Preview("2d · 큰 글자") { InviteCodeView(state: .sample).dynamicTypeSize(.xxxLarge) }
