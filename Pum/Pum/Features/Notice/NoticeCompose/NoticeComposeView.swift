// UI-IOS-3c · REQ-040 — 사장님 공지 작성(확정). 탭 바 없음. 공지에는 수락 버튼이 없고 응답은 연결된 「요청」으로 따로 보낸다.
// 동작은 클로저로만. 보내는 중 · 결과 · 비활성 이유 문구는 디자인이 없어 만들지 않았다.
import SwiftUI

struct NoticeComposeView: View {
    @State private var state: NoticeComposeState
    var onClose: () -> Void
    /// 보낼 내용과 끝 알림 — 실패면 done(false)로 처리 중을 풀고, 성공이면 부르는 쪽이 화면을 닫는다
    var onSend: (NoticeComposeState, _ done: @escaping (_ succeeded: Bool) -> Void) -> Void
    var onAttachPhoto: () -> Void
    var onAttachFile: () -> Void
    /// 「선택」 — 받는 사람을 직접 고르는 화면으로
    var onPickRecipients: () -> Void
    var onOpenRecruitment: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: Field?
    private enum Field { case title, body }

    /// 본문 입력칸 높이 — 원문 본문 7줄(줄 높이 약 25) + 안쪽 여백 ≈ 200, 끝없이 늘어나지 않게 최대를 둔다(넘치면 칸 안에서 스크롤). 토큰 밖이라 이름 상수.
    @ScaledMetric(relativeTo: .body) private var bodyMinHeight: CGFloat = 200
    @ScaledMetric(relativeTo: .body) private var bodyMaxHeight: CGFloat = 320
    /// 카드 안쪽 여백 — 원문 18(토큰 s18)
    private let cardPad = PumTokens.Space.s18
    /// TextEditor 기본 안쪽 여백(약 5)을 지워 글자 시작선을 제목과 맞춘다 — 토큰 s4로 근사
    private let editorInset = PumTokens.Space.s4

    init(state: NoticeComposeState = .sample,
         onClose: @escaping () -> Void = {},
         onSend: @escaping (NoticeComposeState, _ done: @escaping (_ succeeded: Bool) -> Void) -> Void = { _, _ in },
         onAttachPhoto: @escaping () -> Void = {},
         onAttachFile: @escaping () -> Void = {},
         onPickRecipients: @escaping () -> Void = {},
         onOpenRecruitment: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        self.onClose = onClose
        self.onSend = onSend
        self.onAttachPhoto = onAttachPhoto
        self.onAttachFile = onAttachFile
        self.onPickRecipients = onPickRecipients
        self.onOpenRecruitment = onOpenRecruitment
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    categoryChips
                    writeCard
                    settingsCard
                    notice
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: state.sendTitle, kind: .primary, isLoading: state.isSending, action: send)
                .disabled(!state.canSend && !state.isSending)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    /// 연속으로 눌러도 한 번만 보낸다
    private func send() {
        guard state.beginSend() else { return }
        onSend(state) { succeeded in
            if !succeeded { state.failSend() }
        }
    }

    // MARK: 1. 헤더 (공통 PumNavHeader는 뒤로 아이콘만 지원 — 같은 모양을 화면 전용으로. 공통 후보: 닫기 ✕ 지원)

    private var header: some View {
        ZStack {
            Text(NoticeComposeState.screenTitle).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.top, PumTokens.Space.s8)
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    // MARK: 2. 카테고리 칩

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PumTokens.Space.s8) {
                ForEach(Array(NoticeCategory.allCases.enumerated()), id: \.element.id) { i, c in
                    PumChoicePill(title: c.title, isOn: state.category == c, offStyle: .outlined,
                                  position: (i, NoticeCategory.allCases.count)) { select(category: c) }
                }
            }
            .padding(.horizontal, PumTokens.Space.s2) // 외곽선이 스크롤 영역 끝에서 잘리지 않게
        }
        .padding(.horizontal, -PumTokens.Space.s2)
    }

    private func select(category: NoticeCategory) {
        withAnimation(PumMotion.respecting(reduceMotion, PumMotion.fast)) { state.category = category }
    }

    // MARK: 3. 작성 카드

    private var writeCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                TextField("", text: $state.title, axis: .vertical)
                    .lineLimit(1...3)
                    .pumText(.headline, weight: .bold) // 원문 18px 700 → 토큰 단계 17px(headline)·20px(title3) 중 가까운 headline
                    .foregroundStyle(PumColor.textPrimary)
                    .tint(PumColor.accent)
                    .focused($focus, equals: .title)
                    .padding(.vertical, PumTokens.Space.s18)
                    .accessibilityLabel(Text("제목"))
                divider
                // 원문은 날짜만 굵게 보이는 샘플. TextEditor는 일부 굵기를 못 줘서 일반 글자로 둔다(차이 보고).
                TextEditor(text: $state.body)
                    .scrollContentBackground(.hidden)
                    .pumText(.body, weight: .regular) // 15px
                    .foregroundStyle(PumTokens.ColorToken.gray800)
                    .tint(PumColor.accent)
                    .focused($focus, equals: .body)
                    .frame(minHeight: bodyMinHeight, maxHeight: bodyMaxHeight)
                    .padding(.horizontal, -editorInset)
                    .padding(.vertical, PumTokens.Space.s12)
                    .accessibilityLabel(Text("본문"))
                divider
                HStack(spacing: PumTokens.Space.s16) {
                    attach("photo", NoticeComposeState.photoTitle, onAttachPhoto)
                    attach("paperclip", NoticeComposeState.fileTitle, onAttachFile)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, cardPad)
        }
    }

    private func attach(_ icon: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s6) {
                Image(systemName: icon).font(.system(size: PumLayout.navIcon)).accessibilityHidden(true)
                Text(title).pumText(.body, weight: .regular)
            }
            .foregroundStyle(PumColor.textSecondary)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(title) 첨부"))
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    // MARK: 4. 설정 카드

    private var settingsCard: some View {
        PumCard {
            recipientsRow
            rowDivider
            readReceiptRow
            rowDivider
            recruitmentRow
        }
    }

    private var rowDivider: some View {
        divider.padding(.horizontal, PumTokens.Size.rowPadX)
    }

    private var recipientsRow: some View {
        let label = Text(NoticeComposeState.recipientLabel).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let pills = HStack(spacing: PumTokens.Space.s8) {
            audiencePill(state.allTitle, .all, 0)
            audiencePill(NoticeComposeState.hallTitle, .hall, 1)
            audiencePill(NoticeComposeState.selectTitle, .selected, 2)
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { label.fixedSize(); Spacer(minLength: 0); pills }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { label; pills }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private func audiencePill(_ title: String, _ audience: NoticeAudience, _ index: Int) -> some View {
        PumChoicePill(title: title, isOn: state.audience == audience, offStyle: .filled, position: (index, 3)) {
            state.audience = audience
            if audience == .selected { onPickRecipients() }
        }
    }

    private var readReceiptRow: some View {
        Toggle(isOn: $state.requestsReadReceipt) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(NoticeComposeState.readReceiptTitle).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(state.reminderText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text("\(NoticeComposeState.readReceiptTitle), \(state.reminderText)"))
    }

    /// 근무 모집이 없을 때의 행 모양(연결하기 등)은 디자인 없음 — 만들지 않고 요약 줄만 비운다
    private var recruitmentRow: some View {
        Button(action: onOpenRecruitment) {
            HStack(spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(NoticeComposeState.recruitmentTitle).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    if let r = state.recruitment {
                        Text(r.summaryText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s10)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.recruitment.map { "\(NoticeComposeState.recruitmentTitle), \($0.summaryText)" } ?? NoticeComposeState.recruitmentTitle))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 5. 안내

    private var notice: some View {
        Text("공지에는 수락 버튼이 없어요. 응답이 필요한 건 연결된 \(Text("요청").fontWeight(.bold))으로 따로 보내져요.")
            .pumText(.caption, weight: .regular) // 12px
            .foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s4)
    }
}

#Preview("3c 원문") { NoticeComposeView() }
#Preview("3c 빈 상태") { NoticeComposeView(state: .empty(totalStaffCount: 5)) }
