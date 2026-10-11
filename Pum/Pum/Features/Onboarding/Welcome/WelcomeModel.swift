// UI-IOS-2a · REQ-001 · REQ-112 — 시작(로그인 · 가입 공용): 슬로건 5개와 자동 전환 규칙(순수 로직)
import Foundation

/// 슬로건 한 장. 문구는 디자인 원문(Slogan.dc.html) 그대로 — 줄바꿈 위치까지 원문.
struct WelcomeSlogan: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let detail: String

    /// VoiceOver · 접근성용 한 문장(줄바꿈 없이)
    var accessibilityText: String {
        "\(title) \(detail)".replacingOccurrences(of: "\n", with: " ")
    }
}

extension WelcomeSlogan {
    /// 표시 순서(원문 5개)
    static let all: [WelcomeSlogan] = [
        .init(id: 0, title: "일한 만큼,\n정확하게 받기",
              detail: "출퇴근 기록부터 급여 계산까지.\n혼자 써도 되고, 사장님과 함께 쓰면 더 편해요."),
        .init(id: 1, title: "출근은 QR 한 번,\n퇴근은 버튼 한 번",
              detail: "예정 시간이 아니라 실제 기록으로\n근무시간이 만들어져요."),
        .init(id: 2, title: "이번 달 얼마 받을지\n매일 알 수 있어요",
              detail: "기본급·주휴수당·공제까지\n계산 근거를 바로 확인해요."),
        .init(id: 3, title: "사장님은\n확인할 것만 확인해요",
              detail: "정상 근무는 자동 확정,\n연장·지각·누락만 한 번에 처리해요."),
        .init(id: 4, title: "급여명세서까지\n한 번에",
              detail: "근무 확정 → 급여 계산 → 명세서 발행.\n따로 만들 필요 없어요."),
    ]
}

/// 화면 상태. `startIndex`부터 보여 주고, `autoAdvance`가 켜져 있을 때만 자동 전환한다.
struct WelcomeState: Equatable, Sendable {
    var startIndex = 0
    var autoAdvance = true

    /// 원문 캡처(design-2a.png) 비교용 — 3번째 슬로건 고정
    static let sample = WelcomeState(startIndex: 2, autoAdvance: false)
}

enum WelcomeRotation {
    /// 한 슬로건을 보여 주는 시간(초) — 원문 3.2초 · 5개 16초 반복
    static let interval: Double = 3.2

    /// 다음 슬로건 위치(마지막 다음은 처음). 범위 밖 값도 안전하게 보정.
    static func next(after index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index % count) + count + 1) % count
    }

    /// 손으로 넘기거나 점을 누른 뒤 자동 전환을 멈추는 시간(초) — UI-IOS-21i
    static let manualPause: Double = 5

    /// 자동 전환을 돌려도 되는가. 동작 줄이기면 첫 문장 고정(M31 · M22 · 21i),
    /// VoiceOver가 켜져 있으면 읽는 도중 내용이 바뀌므로 멈춘다.
    static func shouldAutoAdvance(enabled: Bool, voiceOver: Bool, reduceMotion: Bool, count: Int) -> Bool {
        enabled && !voiceOver && !reduceMotion && count > 1
    }

    /// 이전 슬로건 위치(처음 이전은 마지막)
    static func previous(before index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index % count) + count - 1) % count
    }

    /// 시작 위치 보정
    static func clamped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(index, 0), count - 1)
    }
}
