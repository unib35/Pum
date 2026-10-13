// UI-IOS-20g · REQ-007 — 근무 마감(앱 없는 직원 확인). 탭 바 없음.
// 8a와 레이아웃이 다른 별도 원문(MVP). 확인할 직원이 남으면 마감 버튼은 회색 비활성, 0명이면 파랑 활성.
// 색: 주황 = 확인 필요 · 체크 완료 = 회색 원 + 먹색 체크. 마감은 한 번만 — 처리 중 잠금, 실패일 때만 풀림.
import SwiftUI

struct WorkClosingDirectView: View {
    var state: WorkClosingDirectState = .sample
    var onBack: () -> Void = {}
    /// 「확인」 — 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패.
    var onConfirm: (_ id: String, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }
    /// 고친 날 열기(직원 id, 날짜 id) — 20f 하루 고치기
    var onOpenDay: (_ personID: String, _ dayID: String) -> Void = { _, _ in }
    var onShowScheduled: (_ id: String) -> Void = { _ in }
    /// 마감 실행. 연결 전 기본값은 실패(done(false)).
    var onClose: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    @State private var lock = WorkClosingDirectLock()
    @ScaledMetric(relativeTo: .body) private var badgeSize = PumLayout.avatar - PumTokens.Space.s12 // 원문 상태 원 약 24pt(8a와 같은 값)

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    summaryCard
                    ForEach(state.people) { person in
                        editedCard(person)
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .disabled(lock.isClosing) // 마감하는 동안은 다른 화면으로 가지 않게
            }
            .scrollBounceBehavior(.basedOnSize)
            closeButton
        }
        .background(PumColor.bgApp)
    }

    // MARK: 위

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text("급여").pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("급여"))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.periodText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 26px 700 → 24px 근사
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // MARK: 요약 카드

    private var summaryCard: some View {
        PumCard {
            appRecordRow
            ForEach(state.people) { person in
                divider
                confirmRow(person)
            }
        }
    }

    private var appRecordRow: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Circle().fill(PumColor.surfaceFill).frame(width: badgeSize, height: badgeSize)
                .overlay { Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(PumColor.textPrimary) }
                .accessibilityHidden(true)
            rowTexts(title: "앱 출퇴근 기록", subtitle: state.appRecordSubtitle)
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("앱 출퇴근 기록, \(state.appRecordSubtitle)"))
    }

    private func confirmRow(_ person: WorkClosingDirectState.Person) -> some View {
        let title = person.confirmTitle(month: state.month)
        return HStack(spacing: PumTokens.Space.s12) {
            Text("!").pumText(.footnote, weight: .heavy).foregroundStyle(PumColor.statusAttention)
                .frame(width: badgeSize, height: badgeSize)
                .background(PumColor.statusAttentionSoft, in: Circle())
                .accessibilityHidden(true)
            rowTexts(title: title, subtitle: person.confirmSubtitle)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(title), \(person.confirmSubtitle)"))
            DirectChip(title: "확인", style: .fill, isLoading: lock.confirmingID == person.id,
                       spoken: "\(person.name) 기록 확인") { confirm(person.id) }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .contain)
    }

    private func rowTexts(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(subtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 고친 날 카드

    private func editedCard(_ person: WorkClosingDirectState.Person) -> some View {
        PumCard {
            Text(person.editedTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 15px 700
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Space.s16)
                .padding(.bottom, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            ForEach(person.editedDays) { day in
                editedRow(person, day)
                divider
            }
            scheduledRow(person)
        }
    }

    private func editedRow(_ person: WorkClosingDirectState.Person, _ day: WorkClosingDirectState.EditedDay) -> some View {
        Button { onOpenDay(person.id, day.id) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                rowTexts(title: day.dateText, subtitle: day.detailText)
                DirectChip(title: "고침", style: .outline, isLoading: false, action: nil) // 행 전체가 버튼
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12) // 원문 padding 12 16
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.spokenText))
        .accessibilityAddTraits(.isButton)
    }

    private func scheduledRow(_ person: WorkClosingDirectState.Person) -> some View {
        Button { onShowScheduled(person.id) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                rowTexts(title: person.scheduledTitle, subtitle: person.scheduledPattern)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12) // 원문 padding 12 16
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(person.scheduledTitle), \(person.scheduledPattern)"))
        .accessibilityAddTraits(.isButton)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }

    // MARK: 하단 버튼

    /// 원문 모양 그대로 — 비활성은 회색 바탕 · 회색 글자(공통 PumButton의 비활성과 다름)
    private var closeButton: some View {
        let active = state.canClose
        return Button(action: close) {
            Group {
                if lock.isClosing {
                    HStack(spacing: PumTokens.Space.s8) {
                        ProgressView().tint(.white)
                        Text("마감하는 중")
                    }
                } else {
                    Text(state.closeTitle)
                }
            }
            .pumText(.headline)
            .foregroundStyle(active ? Color.white : PumColor.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: PumTokens.Size.buttonHSm) // 원문 약 39pt → 터치 44pt 토큰
            .background(active ? PumColor.accent : PumColor.surfaceFill,
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!active || lock.isClosing)
        .accessibilityLabel(Text(state.closeAccessibilityLabel))
        .accessibilityHint(Text(state.closeHint ?? ""))
        .accessibilityValue(lock.isClosing ? Text("마감하는 중") : Text(""))
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s12)
    }

    private func confirm(_ id: String) {
        guard lock.beginConfirm(id: id) else { return }
        onConfirm(id) { _ in lock.finishConfirm() } // 성공이면 서버 새 값으로 다시 그려진다
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func close() {
        guard lock.beginClose(canClose: state.canClose) else { return }
        onClose { success in lock.finishClose(success: success) }
    }
}

/// 카드 안 작은 칩 — 「확인」 회색 칩(PumChipButton 중립과 같은 모양) · 「고침」 흰 바탕 테두리 칩.
/// 보이는 모양은 그대로, 누름 영역만 배경 뒤에서 44pt로 키운다. action이 없으면 표시만.
private struct DirectChip: View {
    enum Style { case fill, outline }
    let title: String
    let style: Style
    let isLoading: Bool
    /// VoiceOver 이름 — 같은 칩이 여러 개일 때 구별(없으면 글자 그대로)
    var spoken: String? = nil
    let action: (() -> Void)?

    private var shape: some View {
        ZStack {
            Text(title).opacity(isLoading ? 0 : 1)
            if isLoading { ProgressView().controlSize(.mini) }
        }
        .pumText(.caption, weight: style == .fill ? .bold : .semibold)
        .foregroundStyle(style == .fill ? PumColor.textPrimary : PumTokens.ColorToken.gray700) // 원문 rgb(91,97,112)
        // 원문 코드: 「확인」 padding 7 11 · 모서리 9 / 「고침」 padding 4 9 · 모서리 8
        .padding(.horizontal, style == .fill ? PumTokens.Space.s10 : PumTokens.Space.s8)
        .padding(.vertical, style == .fill ? PumTokens.Space.s6 : PumTokens.Space.s4)
        .background(style == .fill ? PumColor.surfaceFill : PumColor.surfaceCard,
                    in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)) // 원문 작은 칩 모서리
        .modifier(OutlineRing(enabled: style == .outline, radius: PumTokens.Radius.sm))
    }

    var body: some View {
        if let action {
            Button(action: action) {
                shape
                    // 누름 영역만 44 이상으로 키우고, 배치에는 원문 칩 크기만 쓴다(카드 높이가 늘지 않게)
                    .padding(.vertical, PumTokens.Space.s12)
                    .padding(.horizontal, PumTokens.Space.s4)
                    .contentShape(Rectangle())
                    .padding(.vertical, -PumTokens.Space.s12)
                    .padding(.horizontal, -PumTokens.Space.s4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(spoken ?? title))
            .accessibilityValue(isLoading ? Text("처리 중") : Text(""))
        } else {
            shape
        }
    }
}

private struct OutlineRing: ViewModifier {
    let enabled: Bool
    let radius: CGFloat
    func body(content: Content) -> some View {
        if enabled { content.pumRing(PumTokens.Shadow(x: 0, y: 0, blur: 0, spread: PumTokens.Shadow.hairline.spread, color: PumTokens.ColorToken.gray300), cornerRadius: radius) } else { content }
    }
}

#Preview("20g") { WorkClosingDirectView(state: .sample) }
#Preview("20g · 큰 글자") { WorkClosingDirectView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("20g · 마감 가능") { WorkClosingDirectView(state: .allConfirmed) }
