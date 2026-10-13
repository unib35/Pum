// UI-IOS-5f · REQ-013 — 직원이 보는 초대: 인증 배지 · 대표자 · 미인증이면 경고(확정). 탭 바 · 헤더 없음.
// 미인증은 21g 원문(InviteUnverifiedSections) — 인증됨(.sample) 모양은 그대로(충돌 #36).
// 신고 흐름 디자인은 없다 — 클로저만.
import SwiftUI

struct InviteOfferView: View {
    var state: InviteViewState = .sample
    /// 참여를 끝내면 done(성공 여부)를 부른다 — 실패하면 다시 누를 수 있다
    var onJoin: (_ done: @escaping (Bool) -> Void) -> Void = { $0(false) } // 연결 전 기본값은 미참여
    var onReport: () -> Void = {}

    @State private var lock = InviteJoinLock()
    /// 사업장 색 네모 약 52 — 큰 글자에서 글자와 함께 커진다(공통 후보)
    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 52

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                Text(state.titleText).pumText(.title1).foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                if state.isVerified {
                    workplaceCard
                    termsCard
                } else {
                    InviteUnverifiedSections(state: state) // 21g
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8) // 원문 본문 위 68 = 상태 막대 60 + 8
            .padding(.bottom, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 2. 사업장 카드
    private var workplaceCard: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s14) { // 원문 gap 14
                    Text(state.initial).pumText(.headline, weight: .bold).foregroundStyle(.white)
                        .frame(width: workplaceTile, height: workplaceTile)
                        .background(state.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: PumTokens.Space.s6) { name; badge } // 원문 gap 6
                            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { name; badge }
                        }
                        Text(state.subtitleText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PumTokens.Space.s18) // 원문 padding 16 18
                .padding(.top, PumTokens.Space.s16)
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 선 위 14 · 아래 14
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    facts
                }
                .padding(.horizontal, PumTokens.Space.s18)
                .padding(.top, PumTokens.Space.s14)
                .padding(.bottom, PumTokens.Space.s16)
            }
        }
    }

    private var name: some View {
        Text(state.workplaceName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    /// 인증된 사업장만 — 미인증이면 숨김
    @ViewBuilder private var badge: some View {
        if state.isVerified { PumBadge(text: "\u{2713} 인증된 사업장", kind: .done).accessibilityLabel(Text("인증된 사업장")) }
    }

    /// 2열 정보 4칸 — 넘치면 1열
    private var facts: some View {
        ViewThatFits(in: .horizontal) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 원문 grid gap 8
                HStack(alignment: .top, spacing: PumTokens.Space.s8) { owner; business }
                HStack(alignment: .top, spacing: PumTokens.Space.s8) { inviter; staff }
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { owner; business; inviter; staff }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var owner: some View {
        fact("대표자", state.ownerName, tag: state.ownerTag, spoken: state.ownerAccessibility)
    }
    private var business: some View {
        fact("사업자등록", state.businessNumberMasked, tag: state.operatingTag, spoken: state.businessAccessibility)
    }
    private var inviter: some View {
        fact("초대한 사람", state.inviterValue, tag: nil, spoken: "초대한 사람, \(state.inviterValue)")
    }
    private var staff: some View {
        fact("현재 직원", state.staffValue, tag: nil, spoken: "현재 직원, \(state.staffValue)")
    }

    private func fact(_ label: String, _ value: String, tag: String?, spoken: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 11px 400
            // 값 14px 600, 작은 초록 표시(11px 600)는 값 옆(좁으면 아래)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) { valueText(value); tagText(tag) }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) { valueText(value); tagText(tag) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
    }

    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    @ViewBuilder private func tagText(_ s: String?) -> some View {
        if let s { Text(s).pumText(.caption2, weight: .semibold).foregroundStyle(PumColor.statusDone) }
    }

    // 3. 제안된 근로조건 — 2h와 같은 모양
    private var termsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                Text("제안된 근로조건").pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PumTokens.Space.s18) // 원문 padding 6 18 8 + 제목 8 0 4
                    .padding(.top, PumTokens.Space.s14)
                    .padding(.bottom, PumTokens.Space.s4)
                    .accessibilityAddTraits(.isHeader)
                termRow("시급", state.wageText, isLast: false)
                termRow("근무", state.schedule, isLast: false)
                termRow("급여일", state.payday, isLast: true)
            }
            .padding(.bottom, PumTokens.Space.s8) // 원문 아래 8
        }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private func termRow(_ label: String, _ value: String, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(label)
                Spacer(minLength: 0)
                val(value).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(label)
                val(value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Space.s10) // 원문 padding 9 0 → 가장 가까운 토큰
        .padding(.horizontal, PumTokens.Space.s18)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Space.s18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(value)"))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }
    private func val(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    // 5. 하단 고정
    private var actions: some View {
        VStack(spacing: PumTokens.Space.s10) { // 원문 gap 10
            PumButton(title: "참여하기", kind: .primary, isLoading: lock.isSending, loadingTitle: "참여하는 중", action: join)
            Button(action: onReport) {
                Text("모르는 사업장이에요 · 신고").pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
                    .padding(.vertical, -2) // 원문 높이 40, 누름 영역만 44
            }
            .buttonStyle(.plain)
            .disabled(lock.isSending)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 = 홈 막대 34 + 10
        .background(PumColor.bgApp)
    }

    private func join() {
        guard lock.begin() else { return }
        onJoin { ok in lock.finish(success: ok) }
    }
}

#Preview("5f") { InviteOfferView(state: .sample) }
#Preview("21g") { InviteOfferView(state: .unverifiedSample) }
#Preview("5f · 큰 글자") { InviteOfferView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("21g · 큰 글자") { InviteOfferView(state: .unverifiedSample).dynamicTypeSize(.xxxLarge) }
