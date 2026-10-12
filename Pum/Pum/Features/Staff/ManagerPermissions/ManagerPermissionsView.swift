// UI-IOS-6h · REQ-014 — 관리자 권한(탭 바 없음). 저장 전 값은 draft가 들고, 서버 값이 새로 오면 초안을 다시 받는다.
// 대표 칸은 별도 화면(17j)이라 onSelectOwnerRole만 부른다.
import SwiftUI

struct ManagerPermissionsView: View {
    private let serverState: ManagerPermissionsState
    @State private var draft: ManagerPermissionsDraft
    var isSaving = false
    var onBack: () -> Void
    var onSelectOwnerRole: () -> Void
    var onSave: (ManagerRole, [String]) -> Void

    /// 세그먼트 칸 높이 — 원문 약 36(누름 영역 44)
    @ScaledMetric(relativeTo: .callout) private var segmentHeight: CGFloat = 36
    /// 아바타 — 원문 약 44
    @ScaledMetric(relativeTo: .body) private var avatarSize = PumLayout.avatar + PumTokens.Space.s8

    init(state: ManagerPermissionsState = .sample,
         isSaving: Bool = false,
         onBack: @escaping () -> Void = {},
         onSelectOwnerRole: @escaping () -> Void = {},
         onSave: @escaping (ManagerRole, [String]) -> Void = { _, _ in }) {
        self.serverState = state
        _draft = State(initialValue: state.initialDraft)
        self.isSaving = isSaving
        self.onBack = onBack
        self.onSelectOwnerRole = onSelectOwnerRole
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: ManagerPermissionsState.headerTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    targetBlock
                    segments
                    section(header: Text(ManagerPermissionsState.operationsHeader), group: .operations)
                    section(header: sensitiveHeader, group: .sensitive)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s8)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: serverState) { _, new in draft = new.initialDraft }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    // MARK: 대상

    private var targetBlock: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: serverState.targetName, colorIndex: 0, size: avatarSize).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(serverState.targetName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(serverState.subtitle).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(serverState.targetName), \(serverState.subtitle)"))
    }

    // MARK: 역할 세그먼트 — 공통에 없어 화면 전용(10d와 같은 값)

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(ManagerRole.allCases) { role in
                let selected = role == draft.role
                Button {
                    if role == .owner { onSelectOwnerRole() } else { draft = serverState.changingRole(draft, to: role) }
                } label: {
                    Text(role.title)
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: max(segmentHeight, PumTokens.Size.tapMin))
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous).fill(PumColor.surfaceCard)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(role.title))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 섹션

    private var sensitiveHeader: Text {
        Text("\(Text(ManagerPermissionsState.sensitiveHeader)) · \(Text(serverState.sensitiveSuffix).fontWeight(.medium))")
    }

    private func section(header: Text, group: ManagerPermissionGroup) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            header.pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            PumCard {
                let rows = serverState.items(in: group)
                ForEach(rows) { item in
                    toggleRow(item, isLast: item.id == rows.last?.id)
                }
            }
        }
    }

    private func toggleRow(_ item: ManagerPermissionItem, isLast: Bool) -> some View {
        let locked = serverState.isLocked(item, in: draft)
        let on = serverState.isOn(item, in: draft)
        return Toggle(isOn: Binding(
            get: { on },
            set: { draft = serverState.setting(draft, id: item.id, isOn: $0) }
        )) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                // 원문: 꺼진 급여 묶음 글자는 한 단계 옅은 회색 — 켜짐은 먹색
                Text(item.title).pumText(.callout, weight: .semibold)
                    .foregroundStyle(on || item.group == .operations ? PumColor.textPrimary : PumColor.textSecondary)
                    .multilineTextAlignment(.leading)
                if locked, let note = item.lockedNote {
                    Text(note).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .tint(PumColor.accent)
        .disabled(locked)
        .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityLabel(Text(serverState.spoken(item, in: draft)))
    }

    // MARK: 하단

    private var bottomBar: some View {
        PumButton(title: serverState.saveTitle, kind: .primary, isLoading: isSaving) {
            onSave(draft.role, serverState.enabledIDs(draft))
        }
        .disabled(!serverState.hasChanges(draft) || isSaving)
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }
}

#Preview("6h") { ManagerPermissionsView() }
#Preview("6h · 큰 글자") { ManagerPermissionsView().dynamicTypeSize(.xxxLarge) }
