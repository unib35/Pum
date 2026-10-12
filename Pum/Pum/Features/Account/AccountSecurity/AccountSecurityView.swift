// UI-IOS-6a · REQ-090 — 계정 · 로그인 및 보안 (탭 바 없음).
// 값은 모두 서버/설정 값(let). 토글은 값을 복사하지 않고 Binding으로 읽고, 바꾸면 onToggleBiometricLock만 부른다.
import SwiftUI

struct AccountSecurityView: View {
    let state: AccountSecurityState
    var onBack: () -> Void = {}
    var onChangePhoto: () -> Void = {}
    var onEdit: (AccountField) -> Void = { _ in }
    var onOpenLoginMethod: () -> Void = {}
    var onConnectApple: () -> Void = {}
    var onToggleBiometricLock: (Bool) -> Void = { _ in }
    var onOpenDevices: () -> Void = {}
    var onLogout: () -> Void = {}
    var onWithdraw: () -> Void = {}

    /// 원문 큰 아바타 약 60 · 카메라 표시 약 23 (토큰에 없어 이 화면 상수)
    private let avatarSize: CGFloat = 60
    private let cameraSize: CGFloat = 23

    private var biometricBinding: Binding<Bool> {
        Binding(get: { state.biometricLockOn }, set: { onToggleBiometricLock($0) })
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: AccountSecurityState.headerTitle, onBack: onBack)
                .padding(.top, PumTokens.Space.s8)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                    profileCard
                    PumCard {
                        ForEach([AccountField.name, .phone, .email], id: \.self) { field in
                            valueRow(state.title(for: field), state.value(for: field), isLast: field == .email,
                                     label: state.rowAccessibility(field)) { onEdit(field) }
                        }
                    }
                    section(AccountSecurityState.securityHeader) { securityCard }
                    section(AccountSecurityState.manageHeader) { manageCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    // MARK: 프로필

    private var profileCard: some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s16) {
                avatar
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    Text(state.name).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PumTokens.Space.s8) { PumBadge(text: state.verifiedBadge, kind: .done); detail }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s4) { PumBadge(text: state.verifiedBadge, kind: .done); detail }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.profileAccessibility))
            }
            .padding(PumTokens.Space.s16)
        }
    }

    private var detail: some View {
        Text(state.verifiedDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }

    private var avatar: some View {
        PumAvatar(name: state.name, colorIndex: 0, size: avatarSize)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera.fill")
                    .font(.system(size: cameraSize * 0.45))
                    .foregroundStyle(PumColor.textPrimary)
                    .frame(width: cameraSize, height: cameraSize)
                    .background(PumColor.surfaceCard, in: Circle())
                    .overlay(Circle().strokeBorder(PumColor.borderHairline, lineWidth: 1))
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomTrailing) {
                // 누름 영역 44pt (겉모양은 그대로)
                Button(action: onChangePhoto) {
                    Color.clear.frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .offset(x: PumTokens.Space.s10, y: PumTokens.Space.s10)
                .accessibilityLabel(Text("프로필 사진 바꾸기"))
            }
    }

    // MARK: 로그인 및 보안

    private var securityCard: some View {
        PumCard {
            valueRow(AccountSecurityState.loginMethodTitle, state.loginMethod, isLast: false,
                     label: state.loginMethodAccessibility, action: onOpenLoginMethod)
            appleRow
            toggleRow
            devicesRow
        }
    }

    @ViewBuilder private var appleRow: some View {
        if let status = state.appleStatusText {
            // 연결됨: 눌러도 할 일이 없어 글자만(원문에 모양 없음 — 판단)
            HStack {
                rowTitle(AccountSecurityState.appleTitle)
                Spacer(minLength: PumTokens.Space.s8)
                rowValue(status)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .overlay(alignment: .bottom) { hairline }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(AccountSecurityState.appleTitle), \(status)"))
        } else {
            Button(action: onConnectApple) {
                HStack {
                    rowTitle(AccountSecurityState.appleTitle)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(AccountSecurityState.appleConnect).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.accent)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
                .overlay(alignment: .bottom) { hairline }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(AccountSecurityState.appleTitle), \(AccountSecurityState.appleConnect)"))
            .accessibilityAddTraits(.isButton)
        }
    }

    private var toggleRow: some View {
        Toggle(isOn: biometricBinding) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                rowTitle(state.biometricTitle)
                Text(state.biometricDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) { hairline }
    }

    private var devicesRow: some View {
        Button(action: onOpenDevices) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    deviceText
                    Spacer(minLength: PumTokens.Space.s8)
                    rowValue(state.deviceCountText); chevron
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) { deviceText; rowValue(state.deviceCountText) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.deviceAccessibility))
        .accessibilityAddTraits(.isButton)
    }

    private var deviceText: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            rowTitle(AccountSecurityState.devicesTitle)
            Text(state.deviceSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: 계정 관리

    private var manageCard: some View {
        PumCard {
            Button(action: onLogout) {
                HStack {
                    rowTitle(AccountSecurityState.logoutTitle)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
                .overlay(alignment: .bottom) { hairline }
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            Button(action: onWithdraw) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(AccountSecurityState.withdrawTitle).pumText(.body, weight: .medium).foregroundStyle(PumColor.statusDanger)
                    Spacer(minLength: PumTokens.Space.s8)
                    chevron
                }
                .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: 공통 조각

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: title)
            content()
        }
        .padding(.top, PumTokens.Space.s4)
    }

    private var hairline: some View { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.body.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    /// 제목 + 오른쪽 회색 값 + ›. 값이 길면 제목 아래로.
    private func valueRow(_ title: String, _ value: String, isLast: Bool, label: String,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    rowTitle(title)
                    Spacer(minLength: PumTokens.Space.s8)
                    rowValue(value); chevron
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) { rowTitle(title); rowValue(value).multilineTextAlignment(.leading) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX).padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { if !isLast { hairline } }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(.isButton)
    }

    private func rowTitle(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .medium).foregroundStyle(PumColor.textPrimary)
    }

    private func rowValue(_ s: String) -> some View {
        Text(s).pumText(.footnote).foregroundStyle(PumColor.textSecondary).multilineTextAlignment(.trailing)
    }
}

#Preview("계정 6a") { AccountSecurityView(state: .sample) }
#Preview("계정 6a · 큰 글자") { AccountSecurityView(state: .sample).dynamicTypeSize(.xxxLarge) }
