// UI-IOS-1x · REQ-002 · DEC-005 — 직원 초대 (사장님, 하위 화면, 탭 바 없음)
// 번호로 보내기(알림톡 기본 · 문자 · 앱으로 초대) · 앞에 있으면 QR · 코드. 보내기 · 미리보기 · QR · 복사 · 다시 보내기는 클로저만 부른다.
// 초대 코드 · 남은 일수 · 사업장 이름은 서버 값. 복사는 클립보드에 넣지 않고 클로저로 넘긴다.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만 이름을 붙인다(DEC-005). 사용처에서 @ScaledMetric으로 키운다.
private enum StaffInviteLayout {
    /// 입력칸 높이 — 목업 약 48
    static let fieldHeight: CGFloat = 48
    /// 포커스 테두리 — 목업 약 2
    static let focusLine: CGFloat = 2
    /// 포커스 아닐 때 테두리
    static let restLine: CGFloat = 1
    /// 초대 코드 글자 간격 — 목업 17px 700, 글자 간격 넓게(토큰 밖)
    static let codeTracking: CGFloat = 2
    /// 보내는 방법 칸 높이 — 원문 padding 8 0 + 글자 16
    static let segmentItemHeight: CGFloat = PumTokens.Space.s8 * 2 + PumTokens.Space.s16
    /// 미리보기 줄 높이 — 원문 위 2 + 글자 16
    static let previewRowHeight: CGFloat = PumTokens.Space.s2 + PumTokens.Space.s16
    /// 수락 대기 아바타 — 가까운 PumLayout.avatar 36
    static let avatar: CGFloat = PumLayout.avatar
}

private enum InviteField: Hashable { case name, phone }

struct StaffInviteView: View {
    @State private var draft: StaffInviteDraft
    private let onBack: () -> Void
    private let onSend: (StaffInviteDraft) -> Void
    private let onPreview: (StaffInviteDraft) -> Void
    private let onShowQR: () -> Void
    private let onCopyCode: (String) -> Void
    private let onResend: (PendingInvite) -> Void

    @FocusState private var focus: InviteField?
    private let initialFocus: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var fieldHeight = StaffInviteLayout.fieldHeight
    @ScaledMetric(relativeTo: .callout) private var avatarSize = StaffInviteLayout.avatar

    /// 기본은 빈 입력. `.sample`(원문 캡처)은 번호 칸 포커스 상태로 보여 주려면 `showsPhoneFocus`를 켠다.
    init(draft: StaffInviteDraft = .empty, showsPhoneFocus: Bool = false,
         onBack: @escaping () -> Void = {}, onSend: @escaping (StaffInviteDraft) -> Void = { _ in },
         onPreview: @escaping (StaffInviteDraft) -> Void = { _ in }, onShowQR: @escaping () -> Void = {},
         onCopyCode: @escaping (String) -> Void = { _ in }, onResend: @escaping (PendingInvite) -> Void = { _ in }) {
        _draft = State(initialValue: draft)
        initialFocus = showsPhoneFocus
        self.onBack = onBack
        self.onSend = onSend
        self.onPreview = onPreview
        self.onShowQR = onShowQR
        self.onCopyCode = onCopyCode
        self.onResend = onResend
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "직원 초대", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    verifiedLine
                    inputCard
                    frontCard
                    ForEach(draft.pending) { pendingCard($0) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 머리 줄 아래 14
                .padding(.bottom, PumTokens.Space.s14)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // 이름 · 번호가 비면 비활성 — 이유 문구는 디자인에 없다(충돌 #30과 같은 문제)
            PumButton(title: draft.sendTitle, kind: .primary) { onSend(draft) }
                .disabled(!draft.canSend)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12) // 위 12 · 아래 10(원문 44 − 안전 영역 34)
                .padding(.bottom, PumTokens.Space.s10)
                .background(PumColor.bgApp)
        }
        // 원문 캡처는 번호 칸에 포커스 테두리만 있고 키보드는 없다 — 테두리만 보여 준다(실제 포커스는 주지 않음)
    }

    // MARK: 인증된 사업장

    private var verifiedLine: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { badge; owner }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { badge; owner }
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var badge: some View { PumBadge(text: "\u{2713} 인증된 사업장", kind: .done) }

    private var owner: some View {
        // 목업 13px 400 보조색 → footnote
        Text(draft.ownerLine).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    // MARK: 입력 카드

    private var inputCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 gap 14
                field("이름") {
                    TextField("", text: $draft.name)
                        // 자동 채움이 사장님 본인 정보를 제안하지 않게 내용 종류를 지정하지 않는다
                        .submitLabel(.next)
                        .onSubmit { focus = .phone }
                        .focused($focus, equals: .name)
                        .accessibilityLabel(Text("이름"))
                }
                field("휴대폰 번호") {
                    TextField("", text: $draft.phone)
                        .keyboardType(.numberPad)
                        .toolbar { // 숫자 키패드에는 return 키가 없어 「완료」로 키보드를 내린다
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("완료") { focus = nil }
                            }
                        }
                        // 입력하면 하이픈을 자동으로 붙인다(모델 함수)
                        .onChange(of: draft.phone) { _, new in
                            let f = StaffInviteDraft.formatPhone(new)
                            if f != new { draft.phone = f }
                        }
                        .focused($focus, equals: .phone)
                        .accessibilityLabel(Text("휴대폰 번호"))
                }
                methodBlock
                previewRow
            }
            .padding(PumTokens.Size.rowPadX)
        }
    }

    /// 라벨 + 입력칸(흰 바탕 · hairline · 포커스 파랑 2)
    private func field<F: View>(_ label: String, @ViewBuilder input: () -> F) -> some View {
        let key: InviteField = label == "이름" ? .name : .phone
        let focused = focus == key || (initialFocus && focus == nil && key == .phone)
        return VStack(alignment: .leading, spacing: PumTokens.Space.s6) { // 원문 gap 6
            // 목업 13px 600 gray800 → footnote semibold
            Text(label).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
                .accessibilityHidden(true)
            input()
                .pumText(.body, weight: .regular) // 목업 16px 400 → body(15)
                .foregroundStyle(PumColor.textPrimary)
                .tint(PumColor.accent)
                .padding(.horizontal, PumTokens.Space.s14) // 원문 padding 0 14
                .frame(minHeight: fieldHeight)
                .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                        .strokeBorder(focused ? PumColor.accent : PumColor.borderHairline,
                                      lineWidth: focused ? StaffInviteLayout.focusLine : StaffInviteLayout.restLine)
                }
                .contentShape(Rectangle())
                .onTapGesture { focus = key }
        }
    }

    // MARK: 보내는 방법

    private var methodBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) { // 원문 gap 6
            Text("보내는 방법").pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
                .accessibilityAddTraits(.isHeader)
            segment
            Text(draft.guideText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 회색 둥근 네모 바탕, 선택 칸은 흰 둥근 네모(1j · 1t와 같은 계열, 칸 44)
    private var segment: some View {
        HStack(spacing: 0) {
            ForEach(InviteMethod.allCases, id: \.self) { m in
                let selected = m == draft.method
                Button { draft.method = m } label: {
                    // 목업 14px 선택 600 먹색 / 500 보조색 → callout
                    Text(m.title).pumText(.callout, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                        .background(selected ? PumColor.surfaceCard : .clear,
                                    in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                        .contentShape(Rectangle())
                        // 원문 칸 padding 8 0 → 높이 32(누름 44 유지)
                        .padding(.vertical, -(PumTokens.Size.tapMin - StaffInviteLayout.segmentItemHeight) / 2)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: draft.method)
    }

    private var previewRow: some View {
        Button { onPreview(draft) } label: {
            HStack(spacing: PumTokens.Space.s8) {
                Text("보낼 메시지 미리보기").pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                chevron
            }
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .padding(.vertical, -(PumTokens.Size.tapMin - StaffInviteLayout.previewRowHeight) / 2) // 원문 높이(누름 44 유지)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("보낼 메시지 미리보기"))
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    // MARK: 앞에 있는 직원

    private var frontCard: some View {
        // 원문: 제목은 카드 안 첫 줄
        PumCard {
            // 목업 15px 700 → body bold
            Text("앞에 있는 직원").pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Space.s14) // 원문 padding 14 16 4
                .padding(.bottom, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            qrRow
            Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 전폭 hairline
            codeRow
        }
    }

    private var qrRow: some View {
        Button(action: onShowQR) {
            HStack(spacing: PumTokens.Space.s12) {
                rowTexts(title: "QR 보여주기", detail: "직원 휴대폰 카메라로 스캔 \u{00B7} 2분마다 바뀜")
                chevron
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("QR 보여주기, 직원 휴대폰 카메라로 스캔, 2분마다 바뀜"))
    }

    private func rowTexts(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.callout).foregroundStyle(PumColor.textPrimary) // 목업 14px 600
            Text(detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var codeRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { codeInfo; copyButton }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { codeInfo; copyButton }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    private var codeInfo: some View {
        HStack(spacing: PumTokens.Space.s8) {
            rowTexts(title: "초대 코드", detail: "품 앱 \u{203A} 초대 코드 입력 \u{00B7} 7일 동안")
            // 목업 17px 700 → headline 크기, 글자 간격 넓게 · 고정폭 숫자
            Text(draft.codeDisplay)
                .font(PumFont.font(size: PumTokens.FontToken.headline.size, weight: .bold, relativeTo: .headline))
                .monospacedDigit()
                .tracking(StaffInviteLayout.codeTracking)
                .foregroundStyle(PumColor.textPrimary)
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(draft.codeAccessibility), 품 앱 초대 코드 입력, 7일 동안"))
    }

    private var copyButton: some View {
        PumChipButton(title: "복사") { onCopyCode(draft.inviteCode) } // 원문 12px 700 회색 작은 버튼 = C1 SMALL 칩
            .accessibilityLabel(Text("초대 코드 복사"))
    }

    // MARK: 수락 대기

    private func pendingCard(_ p: PendingInvite) -> some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s12) {
                // 회색 아바타 — PumAvatar 팔레트에 중립색이 없어 같은 모양을 gray 토큰으로 만든다
                Text(p.avatarInitial)
                    .font(PumFont.font(size: StaffInviteLayout.avatar * 0.38, weight: .bold, relativeTo: .callout)) // 글자는 relativeTo로 한 번만 커진다(PumAvatar와 같은 0.38 비율)
                    .foregroundStyle(PumTokens.ColorToken.gray800)
                    .frame(width: avatarSize, height: avatarSize)
                    .background(PumTokens.ColorToken.gray200, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(p.statusText).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                    Text(p.detailText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(p.accessibilityLabel))
                PumChipButton(title: "다시 보내기") { onResend(p) }
                    .accessibilityLabel(Text("\(p.name)에게 다시 보내기"))
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
        }
    }
}

#Preview("1x · 원문 캡처") { StaffInviteView(draft: .sample, showsPhoneFocus: true) }
#Preview("1x · 빈 입력") { StaffInviteView() }
#Preview("1x · 큰 글자") { StaffInviteView(draft: .sample).dynamicTypeSize(.xxxLarge) }
