// UI-IOS-2l · REQ-061 · DEC-005 — 사장님 「직원 상세」: 전화 바로 걸기 · 서류(보건증 등) 만료 관리. 탭 바 없음(하위 화면).
// 개인정보: 전화번호 · 계좌는 서버 값 그대로 보이고, 로그 · 프린트하지 않는다.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만(DEC-005)
private enum StaffDetailLayout {
    /// 큰 아바타(목업 56)
    static let avatar: CGFloat = 56
    /// 연락 버튼 높이(목업 64)
    static let contactH: CGFloat = 64
    /// 연락 버튼 아이콘 · 카카오 로고 자리 검은 원 지름(목업 약 20)
    static let contactIcon: CGFloat = 20
}

struct StaffDetailView: View {
    var state: StaffDetailState = .sample
    var onBack: () -> Void = {}
    var onEdit: () -> Void = {}
    var onCall: () -> Void = {}
    var onMessage: () -> Void = {}
    var onKakao: () -> Void = {}
    var onCallEmergency: () -> Void = {}
    var onRequestDocument: () -> Void = {}
    var onOpenDocument: (String) -> Void = { _ in }

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title) private var avatar = StaffDetailLayout.avatar
    @ScaledMetric(relativeTo: .body) private var contactH = StaffDetailLayout.contactH
    @ScaledMetric(relativeTo: .body) private var contactIcon = StaffDetailLayout.contactIcon

    /// 화면 전용: 디자인 1m 값 #FAE100(카카오 공식 #FEE500과 다름 — 충돌 #23). 공통 후보(1m · 2l 공유)
    private let kakaoYellow = Color(.sRGB, red: 250.0 / 255, green: 225.0 / 255, blue: 0, opacity: 1)

    private var stacked: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "직원 정보", onBack: onBack) {
                Button(action: onEdit) {
                    Text("편집").pumText(.body, weight: .semibold).foregroundStyle(PumColor.accent) // 15px 600
                        .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    profile
                    contactButtons
                    infoCard
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 원문: 머리와 카드 사이 약 8
                        documentsHeader
                        documentsCard
                    }
                    Text(state.notice).pumText(.caption).foregroundStyle(PumColor.textSecondary) // 12px 회색
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12)
                .padding(.bottom, PumTokens.Space.s24)
            }
        }
        .background(PumColor.bgApp)
    }

    private func run(_ style: PumTextStyle, _ weight: Font.Weight) -> Font {
        PumFont.font(size: style.token.size, weight: weight, relativeTo: style.relativeTo)
    }

    // MARK: 아바타 · 이름

    private var profile: some View {
        HStack(spacing: PumTokens.Space.s14) { // 원문 아바타 옆 14
            PumAvatar(name: state.name, colorIndex: state.colorIndex, size: avatar)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.name).pumText(.title3).foregroundStyle(PumColor.textPrimary) // 목업 22px 700 → 20 단계(근사)
                Text(state.summaryText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.headerAccessibilityText))
    }

    // MARK: 연락 버튼 3개

    private var contactButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { phoneButton; messageButton; kakaoButton }
            VStack(spacing: PumTokens.Space.s8) { phoneButton; messageButton; kakaoButton }
        }
    }

    private func contactLabel<Icon: View>(_ title: String, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: PumTokens.Space.s4) { // 원문 아이콘 · 글자 사이 4
            icon().frame(height: contactIcon).accessibilityHidden(true)
            Text(title).pumText(.caption, weight: .semibold).lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.vertical, PumTokens.Space.s8)
        .frame(maxWidth: .infinity, minHeight: contactH)
        .contentShape(Rectangle())
    }

    private var contactShape: RoundedRectangle { RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous) } // DEC-005 버튼 · 타일 12

    private var phoneButton: some View {
        Button(action: onCall) {
            contactLabel("전화") { Image(systemName: "phone").font(.system(size: contactIcon, weight: .regular)) }
                .foregroundStyle(.white)
                .background(PumColor.surfaceInverse, in: contactShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(state.callAccessibilityLabel))
    }

    private var messageButton: some View {
        Button(action: onMessage) {
            contactLabel("문자") { Image(systemName: "bubble.left").font(.system(size: contactIcon, weight: .regular)) }
                .foregroundStyle(PumColor.textPrimary)
                .background(PumColor.surfaceCard, in: contactShape)
                .overlay(contactShape.strokeBorder(PumColor.borderHairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(state.messageAccessibilityLabel))
    }

    private var kakaoButton: some View {
        Button(action: onKakao) {
            // 로고 에셋 없음 — 검은 원으로 대체(충돌 #23)
            contactLabel("카카오톡") { Circle().fill(PumColor.textPrimary).frame(width: contactIcon, height: contactIcon) }
                .foregroundStyle(PumColor.textPrimary)
                .background(kakaoYellow, in: contactShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(state.kakaoAccessibilityLabel))
    }

    // MARK: 연락처 · 계좌 카드

    private var infoCard: some View {
        PumCard {
            VStack(spacing: 0) {
                keyValue("휴대폰", spoken: "휴대폰, \(state.phone)", isLast: !state.hasEmergency && !state.hasAccount,
                         action: onCall, hint: "전화 걸기") {
                    Text(state.phone).pumText(.body, weight: .semibold).foregroundStyle(PumColor.accent)
                }
                if state.hasEmergency, let phone = state.emergencyPhone {
                    keyValue("비상 연락처", spoken: state.emergencyAccessibilityText, isLast: !state.hasAccount,
                             action: onCallEmergency, hint: "전화 걸기") {
                        Text("\(Text(phone).font(run(.body, .semibold)).foregroundColor(PumColor.accent))\(Text(state.emergencyRelation.map { " \u{00B7} \($0)" } ?? "").font(run(.caption, .regular)).foregroundColor(PumColor.textSecondary))")
                            .pumText(.body, weight: .semibold)
                    }
                }
                if state.hasAccount, let account = state.maskedAccount {
                    keyValue("급여 계좌", spoken: "급여 계좌, \(account)", isLast: true, action: nil, hint: nil) {
                        Text(account).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 서버가 가린 그대로
                    }
                }
            }
        }
    }

    /// 키(회색) – 값. 값이 길어지면 값이 아래로. `action`이 있으면 행 전체가 버튼(전화).
    @ViewBuilder
    private func keyValue<Value: View>(_ key: String, spoken: String, isLast: Bool, action: (() -> Void)?, hint: String?,
                                       @ViewBuilder value: () -> Value) -> some View {
        let v = value()
        let content = ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                Text(key).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: PumTokens.Space.s8)
                v.multilineTextAlignment(.trailing).fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text(key).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
                v.multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 13 → 12
        .padding(.horizontal, PumTokens.Space.s18) // 원문 카드 안쪽 18
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, PumTokens.Space.s18)
            }
        }
        if let action {
            Button(action: action) { content.contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(spoken))
                .accessibilityHint(Text(hint ?? ""))
        } else {
            content.accessibilityElement(children: .ignore).accessibilityLabel(Text(spoken))
        }
    }

    // MARK: 서류

    private var documentsHeader: some View {
        HStack {
            Text("서류").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary) // 13px 700
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PumTokens.Space.s8)
            Button(action: onRequestDocument) {
                Text("+ 서류 요청").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.accent)
                    // 보이는 줄은 그대로, 누름 영역만 위아래로 넓혀 44(줄 높이 약 16 + 28)
                    .padding(.vertical, PumTokens.Space.s14)
                    .contentShape(Rectangle())
                    .padding(.vertical, -PumTokens.Space.s14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("서류 요청"))
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var documentsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ForEach(Array(state.documents.enumerated()), id: \.element.id) { i, doc in
                    if i > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 행 사이 전폭 hairline
                    documentRow(doc)
                }
            }
        }
    }

    private func badgeKind(_ t: StaffDocumentTone) -> PumBadge.Kind {
        switch t {
        case .attention: .attention
        case .done: .done
        case .missing: .waiting
        }
    }

    private func documentRow(_ d: StaffDocument) -> some View {
        let missing = d.tone == .missing
        let text = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text("\(Text(d.title).font(run(.body, .semibold)).foregroundColor(missing ? PumColor.textSecondary : PumColor.textPrimary))\(Text(d.qualifier.map { " \($0)" } ?? "").font(run(.caption, .regular)).foregroundColor(PumColor.textSecondary))")
                .pumText(.body, weight: .semibold)
            Text(d.detail)
                .pumText(.caption, weight: d.tone == .attention ? .semibold : .regular)
                .foregroundStyle(d.tone == .attention ? PumColor.statusAttention : (missing ? PumColor.textTertiary : PumColor.textSecondary))
        }
        let status = HStack(spacing: PumTokens.Space.s8) {
            PumBadge(text: d.statusText, kind: badgeKind(d.tone))
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(PumColor.textDisabled)
        }
        return Button { onOpenDocument(d.id) } label: {
            Group {
                if stacked {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) { text; status }
                } else {
                    HStack(spacing: PumTokens.Space.s12) {
                        text.frame(maxWidth: .infinity, alignment: .leading)
                        status
                    }
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(d.accessibilityText))
        .accessibilityHint(Text("서류 보기"))
    }
}

#Preview("2l") { StaffDetailView(state: .sample) }
#Preview("2l · 큰 글자") { StaffDetailView(state: .sample).dynamicTypeSize(.accessibility3) }
