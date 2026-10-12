// UI-IOS-1af · REQ-027 · DEC-005 — 근무기록 직접 추가 (하위 화면, 탭 바 없음)
// 출근 · 퇴근 칸 → C13 시간 선택 시트(#66). 직원 선택 · 날짜 달력은 후속 — 클로저만 호출한다.
import SwiftUI

struct OwnerManualEntryView: View {
    @State private var draft: OwnerManualEntryDraft
    var onClose: () -> Void
    var onPickEmployee: () -> Void
    var onPickDate: () -> Void
    var onSelectTimeField: (OwnerManualEntryField) -> Void
    /// 입력(직원 · 날짜 · 시간 · 휴게)이 바뀌었을 때 — 서버 미리보기 재조회용
    var onInputsChanged: (OwnerManualEntryDraft) -> Void
    var onSubmit: (OwnerManualEntryDraft) async -> Void

    @FocusState private var reasonFocused: Bool
    @State private var pickerOpen = false
    @State private var pickerValue = PumTimeRangeValue()

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 토큰 단계)
    /// 직원 행 작은 아바타 — 목업 약 26
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 26
    /// 시간 칸 최소 너비 — 목업 약 80
    @ScaledMetric(relativeTo: .title3) private var timeCellMinWidth: CGFloat = 80
    /// 시간 칸 최소 높이 — 목업 약 36 (터치는 44 이상으로 맞춘다)
    @ScaledMetric(relativeTo: .title3) private var timeCellMinHeight: CGFloat = 36
    /// 사유 입력칸 최소 높이 — 1i 캡처 약 140 중 가까운 값
    @ScaledMetric(relativeTo: .body) private var reasonHeight: CGFloat = 112
    private let focusLine: CGFloat = 2
    private let restLine: CGFloat = 1

    init(draft: OwnerManualEntryDraft = .initial,
         onClose: @escaping () -> Void = {},
         onPickEmployee: @escaping () -> Void = {},
         onPickDate: @escaping () -> Void = {},
         onSelectTimeField: @escaping (OwnerManualEntryField) -> Void = { _ in },
         onInputsChanged: @escaping (OwnerManualEntryDraft) -> Void = { _ in },
         onSubmit: @escaping (OwnerManualEntryDraft) async -> Void = { _ in }) {
        _draft = State(initialValue: draft)
        self.onClose = onClose
        self.onPickEmployee = onPickEmployee
        self.onPickDate = onPickDate
        self.onSelectTimeField = onSelectTimeField
        self.onInputsChanged = onInputsChanged
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    card
                    if draft.preview != nil { previewBox }
                    reasonSection
                    notice
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            let picked = pickerValue
            changed { $0 = $0.applying(picked: picked) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: OwnerManualEntryDraft.submitTitle, kind: .primary, isLoading: draft.isSending, action: submit)
                .disabled(!draft.canSubmit)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    /// 휴게는 화면에 알약이 있어 끄고, 반복 · 종료일도 끈다. 날짜 행은 화면의 날짜 문구 + 기존 onPickDate(달력 없음)
    private var pickerOptions: PumTimeRangeOptions {
        PumTimeRangeOptions(
            showsDate: true, showsBreak: false, showsRepeat: false, showsEndDate: false,
            intervalMinutes: OwnerManualEntryDraft.pickerIntervalMinutes,
            onDateTap: onPickDate
        )
    }

    private func submit() {
        guard draft.beginSend() else { return }
        let sent = draft
        Task {
            await onSubmit(sent)
            draft.endSend()
        }
    }

    private func changed(_ edit: (inout OwnerManualEntryDraft) -> Void) {
        edit(&draft)
        onInputsChanged(draft)
    }

    // MARK: 1. 헤더

    private var header: some View {
        ZStack {
            Text(OwnerManualEntryDraft.title).pumText(.headline).foregroundStyle(PumColor.textPrimary)
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

    // MARK: 2. 카드 5행

    private var card: some View {
        PumCard {
            employeeRow
            divider
            dateRow
            divider
            timeRow(.start, label: "출근", text: draft.startText)
            divider
            timeRow(.end, label: "퇴근", text: draft.endText)
            divider
            breakRow
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Size.rowPadX)
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func rowLayout<L: View, V: View>(@ViewBuilder label: () -> L, @ViewBuilder value: () -> V) -> some View {
        let l = label(), v = value()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { l.fixedSize(); Spacer(minLength: 0); v }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { l; v }
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private var employeeRow: some View {
        Button(action: onPickEmployee) {
            rowLayout {
                rowLabel("직원")
            } value: {
                HStack(spacing: PumTokens.Space.s8) {
                    if let name = draft.employeeName {
                        PumAvatar(name: name, colorIndex: draft.employeeColorIndex, size: avatarSize)
                        Text(name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    } else {
                        Text("선택").pumText(.body, weight: .semibold).foregroundStyle(PumColor.textTertiary) // 디자인 없음
                    }
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(draft.employeeAccessibility))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("직원을 골라요"))
    }

    private var dateRow: some View {
        rowLayout {
            rowLabel("날짜")
        } value: {
            Button(action: onPickDate) {
                Text(draft.dateText ?? "선택")
                    .pumText(.body, weight: .semibold)
                    .foregroundStyle(draft.dateText == nil ? PumColor.textTertiary : PumColor.textPrimary)
                    .padding(.horizontal, PumTokens.Space.s12)
                    .padding(.vertical, PumTokens.Space.s6) // 원문 캡슐 높이 약 30 — 보이는 크기는 작게, 누르는 영역은 아래에서 44 이상
                    .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .contentShape(Rectangle().inset(by: -PumTokens.Space.s8))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(draft.dateAccessibility))
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("날짜를 골라요"))
        }
    }

    private func timeRow(_ field: OwnerManualEntryField, label: String, text: String) -> some View {
        let on = draft.selectedField == field
        return rowLayout {
            rowLabel(label)
        } value: {
            Button {
                draft.select(field)
                onSelectTimeField(field)
                pickerValue = draft.pickerValue // 열 때 값 복사 — 「완료」 전에 닫으면 화면 값은 그대로
                pickerOpen = true
            } label: {
                // 목업 20px 700 → title3 bold
                Text(text).pumText(.title3, weight: .bold)
                    .foregroundStyle(on ? PumColor.accent : PumColor.textPrimary)
                    .frame(minWidth: timeCellMinWidth, minHeight: timeCellMinHeight) // 원문 약 36 — 누르는 영역은 contentShape로 44 이상
                    .background(on ? PumColor.accentSoftStrong : PumColor.surfaceFill,
                                in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .contentShape(Rectangle().inset(by: -PumTokens.Space.s4))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(draft.timeAccessibility(field)))
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint(Text("위아래로 쓸어 10분씩 바꿔요"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: changed { $0.step(field, by: OwnerManualEntryDraft.stepMinutes) }
                case .decrement: changed { $0.step(field, by: -OwnerManualEntryDraft.stepMinutes) }
                @unknown default: break
                }
            }
        }
    }

    private var breakRow: some View {
        let all = OwnerManualEntryBreak.allCases
        return rowLayout {
            rowLabel("휴게")
        } value: {
            HStack(spacing: PumTokens.Space.s8) {
                ForEach(Array(all.enumerated()), id: \.offset) { index, option in
                    pill(option.title, selected: draft.breakOption == option, filledWhenOff: true,
                         index: index, count: all.count) {
                        changed { $0.setBreak(option) }
                    }
                }
            }
        }
    }

    /// 공통 선택 알약(PumChoicePill) — 휴게는 회색, 사유는 흰 바탕 + hairline
    private func pill(_ title: String, selected: Bool, filledWhenOff: Bool, index: Int, count: Int,
                      action: @escaping () -> Void) -> some View {
        PumChoicePill(title: title, isOn: selected, offStyle: filledWhenOff ? .filled : .outlined,
                      position: (index, count), action: action)
    }

    // MARK: 3. 미리보기 (서버 값)

    private var previewBox: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { previewWork; Spacer(minLength: 0); previewPay }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { previewWork; previewPay }
        }
        .padding(PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(draft.previewAccessibility ?? ""))
    }

    private var previewWork: some View {
        // 원문 13px 400 #5B6170 → footnote, textSecondary
        Text(draft.previewWorkLine ?? "").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    private var previewPay: some View {
        // 서버(엔진) 값 그대로. 13px 700 먹색 + 13px 500 보조색
        Text("\(Text(draft.previewPayText ?? "").fontWeight(.bold).foregroundStyle(PumColor.textPrimary))\(Text(draft.previewNoteText ?? "").fontWeight(.medium).foregroundStyle(PumColor.textSecondary))")
            .pumText(.footnote)
            .multilineTextAlignment(.trailing)
    }

    // MARK: 4. 사유

    private var reasonSection: some View {
        let all = OwnerManualEntryReason.allCases
        return VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("사유\(Text(" *").foregroundStyle(PumColor.statusDanger).fontWeight(.bold))")
                .pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("사유, 필수"))
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, PumTokens.Space.s4)
            OwnerManualEntryFlow(spacing: PumTokens.Space.s8) {
                ForEach(Array(all.enumerated()), id: \.offset) { index, reason in
                    pill(reason.title, selected: draft.reasonChip == reason, filledWhenOff: false,
                         index: index, count: all.count) {
                        draft.toggleReason(reason)
                    }
                }
            }
            TextEditor(text: $draft.reasonText)
                // 200자 자르기는 값이 바뀐 뒤에 — 바인딩 set에서 자르면 한글 조합 중 글자가 끊긴다(1i와 같은 규칙)
                .onChange(of: draft.reasonText) { _, new in
                    let clamped = OwnerManualEntryDraft.clampedReason(new)
                    if clamped != new { draft.reasonText = clamped }
                }
                .focused($reasonFocused)
                .pumText(.callout, weight: .regular) // 목업 14px 400
                .foregroundStyle(PumTokens.ColorToken.gray800)
                .scrollContentBackground(.hidden)
                .padding(PumTokens.Space.s12)
                .frame(minHeight: reasonHeight)
                .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                        .strokeBorder(reasonFocused ? PumColor.accent : PumColor.borderHairline, lineWidth: reasonFocused ? focusLine : restLine)
                }
                .accessibilityLabel(Text("사유 내용"))
        }
    }

    // MARK: 5. 안내

    private var notice: some View {
        Text("\(Text(OwnerManualEntryDraft.notice.lead))\(Text(OwnerManualEntryDraft.notice.strong).fontWeight(.bold))\(Text(OwnerManualEntryDraft.notice.tail))")
            .pumText(.caption).foregroundStyle(PumColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s4)
    }
}

/// 알약이 한 줄에 안 들어가면 줄바꿈
private struct OwnerManualEntryFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, p) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        var origins: [CGPoint] = []
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + spacing; rowH = max(rowH, sz.height); maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowH), origins)
    }
}

#Preview("1af · 처음") { OwnerManualEntryView() }
#Preview("1af · 캡처 상태") { OwnerManualEntryView(draft: .sample) }
#Preview("1af · 큰 글자") { OwnerManualEntryView(draft: .sample).dynamicTypeSize(.accessibility1) }
