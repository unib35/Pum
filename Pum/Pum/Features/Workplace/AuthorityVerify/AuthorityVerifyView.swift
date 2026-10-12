// UI-IOS-5e · REQ-011 — 관리 권한 확인 → 인증 완료(사업장 인증 3 / 3). 탭 바 없음.
// 이름이 다를 때 첫 카드 문구 · 위임 선택 시 미리보기 「권한」 값 · 버튼 문구는 디자인에 없다(만들지 않음).
// 위임을 골라도 미리보기 상자와 버튼 문구는 그대로 둔다(권한 값은 서버 값).
import SwiftUI

struct AuthorityVerifyView: View {
    @State private var state: AuthorityVerifyState
    var onBack: () -> Void
    /// 완료 요청. 끝나면 done(성공 여부) — 실패(false)일 때만 버튼이 풀린다. 연결 전 기본값은 미전송(false).
    var onComplete: (AuthorityChoice, @escaping (Bool) -> Void) -> Void

    init(state: AuthorityVerifyState = .sample,
         onBack: @escaping () -> Void = {},
         onComplete: @escaping (AuthorityChoice, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                topBar
                heading
                VStack(spacing: PumTokens.Space.s12) {
                    representativeCard
                    delegateCard
                }
                .disabled(state.isSubmitting)
                previewBox
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 1. 뒤로 · 단계
    private var topBar: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
            PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
            Spacer(minLength: PumTokens.Space.s8)
            Text("사업장 인증 3 / 3").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.bottom, PumTokens.Space.s4)
    }

    // 2. 제목
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("이 사업장을 관리할\n권한을 확인해요")
                .pumText(.title2)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("대표자가 아니어도 괜찮아요").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        }
    }

    // 3. 선택 카드
    private var representativeCard: some View {
        PumChoiceCard(
            isOn: state.choice == .representative,
            accessibilityLabel: "\(AuthorityVerifyState.representativeTitle), \(state.representativeDetailPlain)",
            accessibilityValue: "2개 중 1번째",
            action: { state.choice = .representative }
        ) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                cardTitle(AuthorityVerifyState.representativeTitle)
                representativeDetail
            }
        }
    }

    private var delegateCard: some View {
        PumChoiceCard(
            isOn: state.choice == .delegate,
            accessibilityLabel: "\(AuthorityVerifyState.delegateTitle), \(AuthorityVerifyState.delegateDetail)",
            accessibilityValue: "2개 중 2번째",
            action: { state.choice = .delegate }
        ) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                cardTitle(AuthorityVerifyState.delegateTitle)
                Text(AuthorityVerifyState.delegateDetail).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            }
        }
    }

    private func cardTitle(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700
    }

    /// 이름만 굵게(13px 700)
    private var representativeDetail: some View {
        var a = AttributedString()
        func part(_ s: String, bold: Bool) {
            var p = AttributedString(s)
            p.foregroundColor = PumColor.textSecondary
            if bold { p.font = PumFont.font(size: PumTokens.FontToken.footnote.size, weight: .bold, relativeTo: .footnote) }
            a += p
        }
        if state.namesMatch {
            part("가입한 이름 ", bold: false)
            part(state.signupName, bold: true)
            part("와 사업자 대표자명 ", bold: false)
            part(state.representativeName, bold: true)
            part("가 일치해요. ", bold: false)
        }
        part(AuthorityVerifyState.representativeTail, bold: false)
        return Text(a).pumText(.footnote)
    }

    // 4. 완료 미리보기(연초록 상자)
    private var previewBox: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s10) { badge; lead }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) { badge; lead }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    miniCard("본인", state.signupName)
                    miniCard("사업자", state.businessStatus)
                    miniCard("권한", state.authorityLabel)
                }
                VStack(spacing: PumTokens.Space.s8) { // 넘치면 세로
                    miniCard("본인", state.signupName)
                    miniCard("사업자", state.businessStatus)
                    miniCard("권한", state.authorityLabel)
                }
            }
            note
        }
        .padding(PumTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.previewAccessibilityText))
    }

    // 공통 후보: 연한 초록 바탕 위 흰 배지(2h와 같은 모양)
    private var badge: some View {
        Text("✓ " + AuthorityVerifyState.previewBadge)
            .pumText(.caption, weight: .bold).foregroundStyle(PumColor.statusDone) // 12px 700
            .padding(.vertical, PumTokens.Space.s4).padding(.horizontal, PumTokens.Space.s10)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
    }

    private var lead: some View {
        Text(AuthorityVerifyState.previewLead).pumText(.caption)
            .foregroundStyle(PumTokens.ColorToken.green700) // 12px 400 · #1F5A40
    }

    private func miniCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 11px 400
            Text("✓ " + value).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.statusDone) // 13px 700
        }
        .padding(.horizontal, PumTokens.Space.s12).padding(.vertical, PumTokens.Space.s10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
    }

    private var note: some View {
        var a = AttributedString(state.noteText)
        a.foregroundColor = PumTokens.ColorToken.green700
        if let r = a.range(of: AuthorityVerifyState.noteBold) {
            a[r].font = PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption)
        }
        return Text(a).pumText(.caption).frame(maxWidth: .infinity, alignment: .leading)
    }

    // 5. 하단 주 버튼
    private var actions: some View {
        PumButton(title: "본인확인하고 인증 완료", kind: .primary, isLoading: state.isSubmitting, loadingTitle: "확인하는 중") { submit() }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }

    private func submit() {
        guard state.canSubmit else { return } // 한 번만
        state.isSubmitting = true
        onComplete(state.choice) { success in
            if !success { state.isSubmitting = false } // 실패일 때만 풀린다
        }
    }
}

#Preview("5e") { AuthorityVerifyView(state: .sample) }
#Preview("5e · 큰 글자") { AuthorityVerifyView(state: .sample).dynamicTypeSize(.xxxLarge) }
