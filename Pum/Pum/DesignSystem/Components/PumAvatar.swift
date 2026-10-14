// C7 Avatar · Store Tile — 사람은 이름 첫 글자 · 6색 순환(상태 의미 없음), 사업장은 모서리 비율 0.3 · 사업장 고유색
// 색 값은 디자인 토큰 avatar-* · store-*(DEC-024, 디자인 시스템 C7)
import SwiftUI

nonisolated enum PumAvatarPalette {
    struct Pair: Equatable, Sendable { let background: Color; let foreground: Color }

    /// C7 순서: 블루 · 자두 · 호박 · 남색 · 초록 · 먹색
    static let people: [Pair] = [
        .init(background: PumTokens.ColorToken.avatar1Bg, foreground: PumTokens.ColorToken.avatar1Fg),
        .init(background: PumTokens.ColorToken.avatar2Bg, foreground: PumTokens.ColorToken.avatar2Fg),
        .init(background: PumTokens.ColorToken.avatar3Bg, foreground: PumTokens.ColorToken.avatar3Fg),
        .init(background: PumTokens.ColorToken.avatar4Bg, foreground: PumTokens.ColorToken.avatar4Fg),
        .init(background: PumTokens.ColorToken.avatar5Bg, foreground: PumTokens.ColorToken.avatar5Fg),
        .init(background: PumTokens.ColorToken.avatar6Bg, foreground: PumTokens.ColorToken.avatar6Fg),
    ]

    /// 사업장 고유색(C7): 블루 · 갈색 · 남색 · 연파랑
    static let stores: [Color] = [PumTokens.ColorToken.store1, PumTokens.ColorToken.store2, PumTokens.ColorToken.store3, PumTokens.ColorToken.store4]

    /// 같은 사람은 항상 같은 색 — 고정 키(사람 ID)로 고른다. 이름 해시는 실행마다 바뀌므로 쓰지 않는다.
    static func person(index: Int) -> Pair { people[((index % people.count) + people.count) % people.count] }

}

/// 사람 아바타(원형, 이름 첫 글자)
struct PumAvatar: View {
    /// 성을 빼고 이름 첫 글자(DEC-021): 한글 두 · 세 글자는 둘째 글자(이선 → 선, 김하늘 → 하),
    /// 네 글자 이상은 두 글자 성으로 보고 셋째 글자(남궁민수 → 민), 한 글자는 그대로, 영문은 첫 글자 대문자(Alex Kim → A).
    nonisolated static func initial(for name: String) -> String {
        let chars = Array(name.trimmingCharacters(in: .whitespaces))
        guard let first = chars.first else { return "" }
        let isHangul = chars.allSatisfy { ("가"..."힣").contains($0) }
        guard isHangul else { return String(first).uppercased() }
        switch chars.count {
        case 1: return String(first)
        case 2, 3: return String(chars[1])
        default: return String(chars[2])
        }
    }

    let name: String
    var colorIndex: Int
    var size: CGFloat = PumLayout.avatar

    var body: some View {
        let pair = PumAvatarPalette.person(index: colorIndex)
        Text(Self.initial(for: name))
            .font(PumFont.font(size: size * 0.38, weight: .bold, relativeTo: .callout))
            .foregroundStyle(pair.foreground)
            .frame(width: size, height: size)
            .background(pair.background, in: Circle())
            .accessibilityHidden(true) // 이름은 옆 글자로 읽는다
    }
}

/// 숫자 타일(「그 밖에 4건」 등) — 주황 = 처리 필요
struct PumCountTile: View {
    let count: Int
    var size: CGFloat = PumLayout.avatar

    var body: some View {
        Text("\(count)")
            .pumText(.callout, weight: .bold)
            .foregroundStyle(PumColor.statusAttention)
            .frame(width: size, height: size)
            .background(PumColor.statusAttentionSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .accessibilityHidden(true)
    }
}
