// UI-IOS-15e · REQ-002 — 코드가 틀렸을 때: 6칸 빨간 테두리 · 오류 문구 · QR · 링크 · 안내. 탭 바 없음.
// 남은 횟수 0 · 10분 잠금 상태의 디자인은 없다(만들지 않음 — 확인 비활성만).
import SwiftUI

struct InviteCodeRetryView: View {
    @State private var state: InviteCodeRetryState
    var onBack: () -> Void
    var onScanQR: () -> Void
    var onLinkHelp: () -> Void
    /// 확인할 코드와 끝 알림 — 실패면 done(false)로 다시 누를 수 있게
    var onConfirm: (String, _ done: @escaping (_ succeeded: Bool) -> Void) -> Void

    @FocusState private var focused: Bool

    init(state: InviteCodeRetryState = .sample,
         onBack: @escaping () -> Void = {},
         onScanQR: @escaping () -> Void = {},
         onLinkHelp: @escaping () -> Void = {},
         onConfirm: @escaping (String, _ done: @escaping (_ succeeded: Bool) -> Void) -> Void = { _, _ in }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onScanQR = onScanQR
        self.onLinkHelp = onLinkHelp
        self.onConfirm = onConfirm
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                PumNavHeader(title: "초대 코드", onBack: onBack)
                Text("사장님께 받은 초대 코드를\n입력해주세요") // 원문 15e 줄바꿈(2d와 다름)
                    .pumText(.title1) // 2d 제목과 같은 단계
                    .foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                codeField
                if let text = state.errorText {
                    // 13px 600 빨강 — 색만이 아니라 문구로 알린다. 6칸 바로 다음에 읽힌다.
                    Text(text)
                        .pumText(.footnote, weight: .semibold)
                        .foregroundStyle(PumColor.statusDanger)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .accessibilityLabel(Text("오류, \(text)"))
                }
                otherWays
                Text("코드에는 0 · O · 1 · I를 쓰지 않아요. 5번 틀리면 10분 뒤에 다시 입력할 수 있어요.")
                    .pumText(.caption, weight: .regular) // 12px 400
                    .foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, PumTokens.Space.s4)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollDismissesKeyboard(.never)
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    private var codeField: some View {
        PumCodeField(code: Binding(get: { state.code }, set: { state.codeChanged(to: $0) }),
                     length: InviteCodeRetryState.codeLength, characters: .alphanumeric,
                     label: "초대 코드", focus: $focused, isError: state.isError)
    }

    // 흰 카드 2행 — 공통 PumRow 재사용(제목 굵기는 공통 값)
    private var otherWays: some View {
        PumCard {
            Button(action: onScanQR) {
                PumRow(title: "QR로 스캔하기", subtitle: "사장님 화면의 초대 QR", showsChevron: true) { EmptyView() }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: onLinkHelp) {
                PumRow(title: "링크로 받았다면", subtitle: "알림톡 · 문자 링크를 누르면 자동으로 채워져요", showsChevron: true, isLast: true) { EmptyView() }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var actions: some View {
        PumButton(title: "초대 확인하기", kind: .primary, isLoading: state.isConfirming, action: confirm)
            .disabled(!state.canConfirm && !state.isConfirming)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }

    /// 연속으로 눌러도 한 번만 보낸다
    private func confirm() {
        guard state.beginConfirm() else { return }
        onConfirm(state.code) { succeeded in
            if !succeeded { state.failConfirm() }
        }
    }
}

#Preview("15e") { InviteCodeRetryView(state: .sample) }
#Preview("15e · 큰 글자") { InviteCodeRetryView(state: .sample).dynamicTypeSize(.xxxLarge) }
