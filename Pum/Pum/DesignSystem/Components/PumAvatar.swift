// C7 Avatar · Store Tile — 사람은 이름 첫 글자 · 6색 순환(상태 의미 없음), 사업장은 모서리 비율 0.3 · 사업장 고유색
// 색 값은 디자인 시스템 C7 카드 기준(tokens/*.css에 없는 색 — README 충돌 표 참고)
import SwiftUI

nonisolated enum PumAvatarPalette {
    struct Pair: Equatable, Sendable { let background: Color; let foreground: Color }

    /// C7 순서: 블루 · 자두 · 호박 · 남색 · 초록 · 먹색
    static let people: [Pair] = [
        .init(background: PumColor.accentSoftStrong, foreground: PumColor.accent),                     // #D6DFFB / #2F5BEA
        .init(background: rgb(0xEA, 0xD9, 0xE5), foreground: rgb(0x6B, 0x3A, 0x5B)),
        .init(background: rgb(0xF3, 0xE3, 0xCF), foreground: rgb(0x7A, 0x4A, 0x12)),
        .init(background: rgb(0xE2, 0xE4, 0xF0), foreground: rgb(0x3B, 0x42, 0x70)),
        .init(background: rgb(0xD8, 0xE8, 0xDF), foreground: PumTokens.ColorToken.green700),         // #1F5A40
        .init(background: PumColor.surfaceInverse, foreground: .white),
    ]

    /// 사업장 고유색(C7): 블루 · 갈색 · 남색
    static let stores: [Color] = [PumColor.accent, rgb(0x8A, 0x5A, 0x2B), rgb(0x3B, 0x42, 0x70)]

    /// 같은 사람은 항상 같은 색 — 고정 키(사람 ID)로 고른다. 이름 해시는 실행마다 바뀌므로 쓰지 않는다.
    static func person(index: Int) -> Pair { people[((index % people.count) + people.count) % people.count] }

    private static func rgb(_ r: Int, _ g: Int, _ b: Int) -> Color {
        Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
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
