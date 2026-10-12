// UI-IOS-6f · REQ-023 — 앱 권한: 무엇을 왜 쓰는지, 쓰지 않는 권한까지 (탭 바 없음). 행은 누르지 않는다.
import SwiftUI

struct AppPermissionsView: View {
    let state: AppPermissionsState
    var onBack: () -> Void = {}
    var onOpenSettings: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: AppPermissionsState.headerTitle, onBack: onBack)
                .padding(.top, PumTokens.Space.s8)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    Text(AppPermissionsState.intro)
                        .pumText(.caption)
                        .foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PumCard {
                        ForEach(state.rows) { row in
                            permissionRow(row, isLast: row.id == state.rows.last?.id)
                        }
                    }
                    PumSectionHeader(title: AppPermissionsState.unrequestedHeader)
                        .padding(.top, PumTokens.Space.s8)
                    PumCard {
                        Text(AppPermissionsState.unrequestedBody)
                            .pumText(.footnote)
                            .foregroundStyle(PumColor.textPrimary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Space.s16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    private func permissionRow(_ row: AppPermissionRow, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                iconTile(row.kind)
                titleBlock(row.kind).frame(maxWidth: .infinity, alignment: .leading)
                statusText(row.status)
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                iconTile(row.kind)
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    titleBlock(row.kind)
                    statusText(row.status).multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.rowAccessibility(row)))
    }

    private func iconTile(_ kind: AppPermissionKind) -> some View {
        Image(systemName: kind.symbol)
            .font(.callout)
            .foregroundStyle(PumColor.textPrimary)
            .frame(width: PumLayout.avatar, height: PumLayout.avatar)
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .accessibilityHidden(true)
    }

    private func titleBlock(_ kind: AppPermissionKind) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(kind.title).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
            Text(kind.reason).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
    }

    private func statusText(_ s: AppPermissionStatus) -> some View {
        Text(s.text)
            .pumText(.caption, weight: .semibold)
            .foregroundStyle(s.isActive ? PumColor.statusDone : PumColor.textSecondary)
            .multilineTextAlignment(.trailing)
    }

    private var bottomBar: some View {
        PumButton(title: AppPermissionsState.openSettingsTitle, kind: .outline, action: onOpenSettings)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s8)
            .background(PumColor.bgApp)
    }
}

#Preview("앱 권한 6f") { AppPermissionsView(state: .sample) }
#Preview("앱 권한 6f · 큰 글자") { AppPermissionsView(state: .sample).dynamicTypeSize(.xxxLarge) }
