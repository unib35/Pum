// UI-IOS-2h · REQ-005 — 직원 온보딩: 초대 수락 → 전환(확정). 헤더 · 탭 바 없음.
// 개인 기록은 그대로 남고 수락 이후부터 사업장 기록. 거절 확인 화면은 디자인에 없다(클로저만).
import SwiftUI

struct InviteSwitchView: View {
    var state: InviteSwitchState = .sample
    /// 수락을 끝내면 done(성공 여부)를 부른다 — 실패하면 다시 누를 수 있다
    var onAccept: (_ done: @escaping (Bool) -> Void) -> Void = { $0(false) } // 연결 전 기본값은 미수락
    var onDecline: () -> Void = {}

    @State private var lock = InviteSwitchLock()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                heading
                changeCard
                termsCard
                Text("수락 후 근로계약서에 서명하면 정식 소속이 돼요.")
                    .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, PumTokens.Space.s4)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 1. 큰 제목 — 사업장 이름만 파랑
    private var heading: some View {
        var lead = AttributedString(state.titleLead + "\n"); lead.foregroundColor = PumColor.textPrimary
        var name = AttributedString(state.workplaceName); name.foregroundColor = PumColor.accent
        var tail = AttributedString(state.titleTail); tail.foregroundColor = PumColor.textPrimary
        return Text(lead + name + tail)
            .pumText(.title1) // 목업 26px 700 → title1(28, 1o와 같음)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.titleText))
            .accessibilityAddTraits(.isHeader)
    }

    // 2. 바뀌는 점 비교 카드
    private var changeCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                Text("수락하면 이렇게 바뀌어요").pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                comparison
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                note
            }
            .padding(PumTokens.Space.s16)
        }
    }

    /// 두 상자 — 좁으면(큰 글자) 위아래로 쌓고 화살표는 ↓
    private var comparison: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                personalBox
                arrow("arrow.right")
                workplaceBox
            }
            VStack(spacing: PumTokens.Space.s8) {
                personalBox
                arrow("arrow.down")
                workplaceBox
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.comparisonAccessibilityText))
    }

    private func arrow(_ name: String) -> some View {
        Image(systemName: name).font(.body.weight(.semibold)).foregroundStyle(PumColor.textSecondary)
    }

    private var personalBox: some View {
        box(fill: PumColor.surfaceFill) {
            PumMyRecordTag()
            title(state.personalName)
            detail(state.personalPeriod)
            detail(InviteSwitchState.personalDetail)
        }
    }

    private var workplaceBox: some View {
        box(fill: PumColor.statusDoneSoft) {
            // 공통 후보: 연한 초록 바탕 위 흰 배지(PumBadge .done은 연초록 바탕이라 이 위에서 묻힘)
            Text("✓ " + InviteSwitchState.badgeText)
                .pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
                .padding(.vertical, PumTokens.Space.s4).padding(.horizontal, 9) // PumBadge와 같은 안쪽 여백
                .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            title(state.workplaceName)
            detail(state.startDate)
            detail(InviteSwitchState.workplaceDetail)
        }
    }

    private func box<C: View>(fill: Color, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) { content() }
            .padding(PumTokens.Space.s12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    private func title(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 14px 600
    }
    private func detail(_ s: String) -> some View {
        Text(s).pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }

    private var note: some View {
        var a = AttributedString(state.noteText)
        a.foregroundColor = PumColor.textSecondary
        if let r = a.range(of: state.noteBold) {
            a[r].font = PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption)
        }
        return Text(a).pumText(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 3. 제안 근로조건
    private var termsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                Text("사장님이 제안한 근로조건").pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
                    .padding(.top, PumTokens.Space.s12)
                    .padding(.bottom, PumTokens.Space.s4)
                    .accessibilityAddTraits(.isHeader)
                termRow("시급", value: state.hourlyWage, match: state.wageMatchesMine, a11y: state.wageAccessibilityText)
                termRow("근무", value: state.schedule, a11y: "근무, \(state.schedule)")
                termRow("급여일", value: state.payday, isLast: true, a11y: "급여일, \(state.payday)")
            }
        }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private func termRow(_ label: String, value: String, match: Bool = false, isLast: Bool = false, a11y: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(label)
                Spacer(minLength: 0)
                valueView(value, match: match).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(label)
                valueView(value, match: match)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(a11y))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary) // 14px 400
    }

    private func valueView(_ s: String, match: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s4) {
            Text(s).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 14px 600
            if match {
                Text(InviteSwitchState.matchText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone) // 12px 600
            }
        }
    }

    // 5. 하단 고정
    private var actions: some View {
        VStack(spacing: PumTokens.Space.s4) {
            PumButton(title: "초대 수락 · 계약서 보기", kind: .primary, isLoading: lock.isSending, loadingTitle: "수락하는 중", action: accept)
            Button(action: onDecline) {
                Text("거절").pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary) // 14px 400
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(lock.isSending)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s4)
        .background(PumColor.bgApp)
    }

    private func accept() {
        guard lock.begin() else { return }
        onAccept { ok in lock.finish(success: ok) }
    }
}

#Preview("2h") { InviteSwitchView(state: .sample) }
#Preview("2h · 큰 글자") { InviteSwitchView(state: .sample).dynamicTypeSize(.accessibility3) }
