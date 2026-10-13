// UI-IOS-10l · REQ-020 · REQ-021 — 출근 확인 방식 (하위 화면, 탭 바 없음).
// 방식 목록 · 반경 선택지 · 주소 · 대체 경로 문구는 서버 값. 공용기기는 충돌 #10 — 서버 isAvailable이 false면 흐리게 · 선택 불가.
// 위치를 쓰지 않는 방식(QR만 · 관리자 확인)이면 「위치」 섹션을 그대로 두되 흐리게 · 잠근다(원문 없음).
// 저장은 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다. 바뀐 게 없으면 저장 비활성. 출퇴근 기록은 이 화면과 무관하게 막지 않는다.
import SwiftUI

struct CheckInMethodView: View {
    var state: CheckInMethodState = .sample
    var onBack: () -> Void = {}
    var onPickLocation: () -> Void = {}
    var onPickFallback: () -> Void = {}
    /// 출근 QR 저장 화면(10m)
    var onOpenQR: () -> Void = {}
    /// 저장. 결과를 done(성공 여부)으로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSave: (_ policy: CheckInPolicy, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }

    @State private var draft: CheckInMethodDraft
    @State private var lock = CheckInMethodLock()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 세그먼트 칸 높이 — 원문 약 36(누름 영역은 위아래로 넓혀 44)
    @ScaledMetric(relativeTo: .callout) private var segmentHeight: CGFloat = 36

    init(state: CheckInMethodState = .sample,
         onBack: @escaping () -> Void = {}, onPickLocation: @escaping () -> Void = {},
         onPickFallback: @escaping () -> Void = {}, onOpenQR: @escaping () -> Void = {},
         onSave: @escaping (_ policy: CheckInPolicy, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onPickLocation = onPickLocation
        self.onPickFallback = onPickFallback
        self.onOpenQR = onOpenQR
        self.onSave = onSave
        _draft = State(initialValue: CheckInMethodDraft(state.policy))
    }

    private var isSaving: Bool { lock.isSaving }
    private var locationLocked: Bool { !draft.method.usesLocation }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: CheckInMethodState.headerTitle, onBack: isSaving ? nil : onBack) { EmptyView() }
                .padding(.top, PumTokens.Space.s8)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    section(CheckInMethodState.methodHeader) { methodCard }
                    section(CheckInMethodState.locationHeader) { locationCard }
                    otherCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: draft)
    }

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s10) {
            PumButton(title: CheckInMethodState.saveTitle, kind: .dark, isLoading: isSaving, action: save)
            Text(CheckInMethodState.notice).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: title)
            content()
        }
    }

    private func divider(show: Bool) -> some View {
        Rectangle().fill(show ? PumColor.borderHairline : Color.clear).frame(height: 1)
    }

    // MARK: 방식

    private var methodCard: some View {
        PumCard {
            ForEach(Array(state.options.enumerated()), id: \.element.id) { index, option in
                methodRow(option)
                    .overlay(alignment: .bottom) { divider(show: index < state.options.count - 1) }
            }
        }
    }

    /// 공통 후보: 제목 + 배지 + 설명 두 줄 라디오 행 (PumRadioRow는 한 줄)
    private func methodRow(_ option: CheckInMethodOption) -> some View {
        let isOn = draft.method == option.kind
        return Button {
            guard !isSaving else { return }
            draft.select(option)
        } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    titleLine(option)
                    Text(option.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!option.isAvailable || isSaving)
        .opacity(option.isAvailable ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        // 「선택됨」이 라벨에 있어 isSelected 특성은 붙이지 않는다(두 번 읽힘)
        .accessibilityLabel(Text(state.optionAccessibility(option, isOn: isOn)))
        .accessibilityAddTraits(.isButton)
    }

    /// 제목 + 배지. 큰 글자에서 한 줄에 안 들어가면 배지를 아래로
    private func titleLine(_ option: CheckInMethodOption) -> some View {
        // 목업 15px 600 → callout semibold
        let title = Text(option.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) { title; badge(option) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { title; badge(option) }
        }
    }

    @ViewBuilder private func badge(_ option: CheckInMethodOption) -> some View {
        if let badge = option.badge {
            PumBadge(text: badge.text, kind: badge.tone == .recommended ? .active : .waiting)
        }
    }

    // MARK: 위치

    private var locationCard: some View {
        PumCard {
            linkRow(title: CheckInMethodState.addressTitle, value: state.address, isLast: false,
                    action: onPickLocation)
            radiusRow
        }
        .opacity(locationLocked ? 0.5 : 1)
        .disabled(locationLocked || isSaving)
    }

    private var radiusRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { radiusKey; segments }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { radiusKey; segments }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s8)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    private var radiusKey: some View {
        Text(CheckInMethodState.radiusTitle).pumText(.callout).foregroundStyle(PumTokens.ColorToken.gray800)
            .accessibilityHidden(true)
    }

    /// 공통 후보: 세그먼트 컨트롤(8d와 같은 모양 — 흰 선택 알약). 글자는 한 줄로 두고, 모자라면 키 아래로 내려 폭을 넓힌다.
    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(state.radiusChoices, id: \.self) { meters in
                let selected = meters == draft.radiusMeters
                Button {
                    guard !isSaving else { return }
                    draft.selectRadius(meters, in: state)
                } label: {
                    Text(CheckInMethodState.radiusText(meters))
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, minHeight: segmentHeight)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                                    .fill(PumColor.surfaceCard)
                            }
                        }
                        .contentShape(Rectangle().inset(by: -PumTokens.Space.s4))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(CheckInMethodState.radiusAccessibility(meters, isOn: selected)))
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 대체 경로 · 출근 QR

    private var otherCard: some View {
        PumCard {
            linkRow(title: CheckInMethodState.fallbackTitle, value: state.fallbackValue, isLast: false, action: onPickFallback)
            linkRow(title: CheckInMethodState.qrTitle, value: state.qrValue, isLast: true, action: onOpenQR)
        }
        .disabled(isSaving)
    }

    /// 키–값 › 행(4c와 같은 모양). 큰 글자에서 한 줄에 안 들어가면 키 아래에 값.
    private func linkRow(title: String, value: String, isLast: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    keyText(title)
                    Spacer(minLength: PumTokens.Space.s8)
                    valueText(value)
                    chevron
                }
                HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        keyText(title)
                        valueText(value).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: PumTokens.Space.s8)
                    chevron
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { divider(show: !isLast) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title), \(value)"))
        .accessibilityAddTraits(.isButton)
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.callout).foregroundStyle(PumTokens.ColorToken.gray800)
    }

    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    // MARK: 동작

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func save() {
        guard lock.begin() else { return } // 원문은 저장 버튼이 늘 켜져 있다 — 바뀐 게 없어도 보낼 수 있다
        onSave(draft.policy) { success in lock.finish(success: success) }
    }
}

#Preview("10l") { CheckInMethodView(state: .sample) }
#Preview("10l · 큰 글자") { CheckInMethodView(state: .sample).dynamicTypeSize(.xxxLarge) }
