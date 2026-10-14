// UI-IOS-2a · REQ-001 · REQ-112 · DEC-005 — 시작(로그인 · 가입 공용, 슬로건 자동 전환). 탭 바 · 헤더 없음.
// 실제 로그인 · SDK 연동은 하지 않고 클로저만 둔다(후속). 원문 캡처 비교: `WelcomeView(state: .sample)`.
import SwiftUI

struct WelcomeView: View {
    var state: WelcomeState = .init()
    var onKakao: () -> Void = {}
    var onApple: () -> Void = {}
    var onPhone: () -> Void = {}

    @State private var index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    /// 손으로 넘기거나 점을 누르면 늘어나 자동 전환을 5초 멈춘 뒤 다시 시작한다(21i)
    @State private var manualTurn = 0

    private let slogans = WelcomeSlogan.all

    /// 목업 로고 네모 56 — 토큰에 없어 이름을 붙임(DEC-005), 큰 글자에서 글자와 함께 커진다
    @ScaledMetric(relativeTo: .largeTitle) private var logoSize: CGFloat = 56
    /// 목업 슬로건 점 6 · 현재 점 너비 18 — space-6 · space-18
    private let dot = PumTokens.Space.s6
    private let dotCurrentWidth = PumTokens.Space.s18

    init(state: WelcomeState = .init(), onKakao: @escaping () -> Void = {},
         onApple: @escaping () -> Void = {}, onPhone: @escaping () -> Void = {}) {
        self.state = state
        self.onKakao = onKakao
        self.onApple = onApple
        self.onPhone = onPhone
        _index = State(initialValue: WelcomeRotation.clamped(state.startIndex, count: WelcomeSlogan.all.count))
    }

    private var autoRuns: Bool {
        WelcomeRotation.shouldAutoAdvance(enabled: state.autoAdvance, voiceOver: voiceOver,
                                          reduceMotion: reduceMotion, count: slogans.count)
            && scenePhase == .active
    }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                // 아주 큰 글자: 버튼도 함께 스크롤 — 잘림 · 겹침 방지
                ScrollView {
                    VStack(spacing: PumTokens.Space.s24) {
                        hero
                        VStack(spacing: PumTokens.Space.s16) { buttons; terms }
                    }
                    .padding(.vertical, PumTokens.Space.s24)
                }
            } else {
                // 슬로건은 버튼 위 영역의 가운데(원문), 버튼은 아래 고정. 작은 화면이면 슬로건 쪽만 스크롤.
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        ScrollView {
                            hero
                                .padding(.vertical, PumTokens.Space.s24)
                                .frame(minHeight: geo.size.height)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    VStack(spacing: PumTokens.Space.s16) { buttons; terms }
                        .padding(.top, PumTokens.Space.s12)
                        .padding(.bottom, PumTokens.Space.s10) // 원문 하단 44 − 홈 막대 안전 영역 34
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .background(PumColor.bgApp)
        .task(id: AutoKey(runs: autoRuns, turn: manualTurn)) { await runAutoAdvance() }
        // 21i: 동작 줄이기면 첫 문장 고정, 백그라운드에서 돌아오면 1번부터
        .onChange(of: reduceMotion, initial: true) { _, on in if on && state.autoAdvance { index = 0 } }
        .onChange(of: scenePhase) { old, new in
            if new == .active, old != .active, state.autoAdvance { index = 0 }
        }
    }

    // MARK: 1 · 2. 로고 + 슬로건 + 점

    private var hero: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s24) {
            Text("품").pumText(.title2, weight: .heavy).foregroundStyle(.white) // 26px 800 → title2(24) 근사
                .frame(width: logoSize, height: logoSize)
                .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
                .accessibilityHidden(true)
            sloganBlock
                .contentShape(Rectangle())
                .gesture(swipe)
            dots
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s8) // 원문: 로고 · 슬로건은 버튼보다 약 8 안쪽(28)
    }

    private var sloganBlock: some View {
        let s = slogans[index]
        return VStack(alignment: .leading, spacing: PumTokens.Space.s20) {
            // 제목 30px 700 → 가까운 단계 hero(32) — title1(28)과 같은 거리라 큰 쪽(DEC-005)
            Text(s.title).pumText(.hero).foregroundStyle(PumColor.textPrimary)
            Text(s.detail).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(s.id)
        .transition(sloganTransition)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(s.accessibilityText)) // 현재 슬로건만 읽는다
        .accessibilityValue(Text("\(slogans.count)개 중 \(index + 1)번째"))
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: go(to: WelcomeRotation.next(after: index, count: slogans.count))
            case .decrement: go(to: WelcomeRotation.previous(before: index, count: slogans.count))
            @unknown default: break
            }
        }
    }

    /// 원문: 아래 14에서 올라오며 나타나고, 위로 10 올라가며 사라짐. 동작 줄이기(M22)면 이동 없이 페이드만.
    private var sloganTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: PumTokens.Space.s14)),
            removal: .opacity.combined(with: .offset(y: -PumTokens.Space.s10)))
    }

    private var dots: some View {
        HStack(spacing: PumTokens.Space.s6) {
            ForEach(slogans.indices, id: \.self) { i in
                // 점을 누르면 그 문장으로(21i). 보이는 크기는 원문, 누름 영역만 위아래로 넓힌다.
                Button { go(to: i) } label: {
                    Capsule()
                        .fill(i == index ? PumColor.surfaceInverse : PumTokens.ColorToken.gray300)
                        .frame(width: i == index ? dotCurrentWidth : dot, height: dot)
                        .padding(.vertical, PumTokens.Space.s20)
                        .contentShape(Rectangle())
                        .padding(.vertical, -PumTokens.Space.s20)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.base), value: index)
        // VoiceOver는 슬로건 요소에서 위아래로 쓸어 넘긴다 — 점은 숨김
        .accessibilityHidden(true)
    }

    // MARK: 3. 버튼 3개 · 4. 약관 안내

    private var buttons: some View {
        VStack(spacing: PumTokens.Space.s10) {
            WelcomeProviderButton(title: "카카오로 계속하기", style: .kakao, action: onKakao)
            WelcomeProviderButton(title: "Apple로 계속하기", style: .apple, action: onApple)
            PumButton(title: "휴대폰 번호로 계속하기", kind: .outline, action: onPhone)
        }
    }

    private var terms: some View {
        Text("계속하면 이용약관과 개인정보 처리방침에 동의하는 거예요")
            .pumText(.caption).foregroundStyle(PumColor.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: 손으로 넘기기 · 점 누르기(21i)

    private var swipe: some Gesture {
        DragGesture(minimumDistance: PumTokens.Space.s20)
            .onEnded { v in
                let w = v.translation.width
                guard abs(w) > abs(v.translation.height) else { return }
                if w < 0 { go(to: WelcomeRotation.next(after: index, count: slogans.count)) }
                else { go(to: WelcomeRotation.previous(before: index, count: slogans.count)) }
            }
    }

    private func go(to i: Int) {
        withAnimation(PumMotion.respecting(reduceMotion, PumMotion.base)) { index = i }
        manualTurn += 1 // 자동 전환을 5초 멈췄다가 다시
    }

    private struct AutoKey: Equatable { let runs: Bool; let turn: Int }

    // MARK: 자동 전환 — 화면이 사라지거나 백그라운드면 task가 취소되어 멈춘다

    private func runAutoAdvance() async {
        guard autoRuns else { return }
        if manualTurn > 0 {
            do { try await Task.sleep(for: .seconds(WelcomeRotation.manualPause - WelcomeRotation.interval)) } catch { return }
        }
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(WelcomeRotation.interval)) } catch { return }
            withAnimation(PumMotion.respecting(reduceMotion, PumMotion.base)) {
                index = WelcomeRotation.next(after: index, count: slogans.count)
            }
        }
    }
}

// MARK: - 로그인 방법 버튼 (공통 후보: 소셜 로그인 버튼)

/// 카카오(노랑) · Apple(먹색) 버튼. 높이 54 · 모서리 12 · 큰 글자에서는 줄바꿈으로 늘어난다.
private struct WelcomeProviderButton: View {
    enum Style { case kakao, apple }
    let title: String
    let style: Style
    let action: () -> Void

    /// 카카오 공식 노랑 #FEE500(DEC-025)
    private static let kakaoYellow = PumTokens.ColorToken.kakaoYellow
    /// 검은 원 로고 자리(에셋 없음, 충돌 #23) — space-20
    private let logoDot = PumTokens.Space.s20

    var body: some View {
        if style == .apple {
            Button(action: action) { label }
                .buttonStyle(PumButtonStyle(kind: .dark, size: .regular, enabled: true))
        } else {
            Button(action: action) { label }
                .buttonStyle(KakaoButtonStyle(fill: Self.kakaoYellow))
        }
    }

    private var label: some View {
        HStack(spacing: PumTokens.Space.s8) {
            icon.accessibilityHidden(true)
            Text(title).multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.buttonH)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var icon: some View {
        switch style {
        case .kakao: Circle().fill(PumColor.textPrimary).frame(width: logoDot, height: logoDot)
        case .apple: Image(systemName: "apple.logo")
        }
    }
}

/// 노랑 바탕 · 먹색 글자 · 누름 M1(scale .97, 동작 줄이기면 생략)
private struct KakaoButtonStyle: ButtonStyle {
    let fill: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pumText(.headline)
            .foregroundStyle(PumColor.textPrimary)
            .background(fill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PumMotion.respecting(reduceMotion, PumMotion.press), value: configuration.isPressed)
    }
}

#Preview("2a") { WelcomeView() }
#Preview("2a · 원문 캡처") { WelcomeView(state: .sample) }
#Preview("2a · 큰 글자") { WelcomeView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("2a · 접근성 큰 글자") { WelcomeView(state: .sample).dynamicTypeSize(.accessibility3) }
