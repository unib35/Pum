// F3 Type — Pretendard v1.3.9 (SIL OFL 1.1, Resources/Fonts/Pretendard-LICENSE.txt)
// 앱 번들의 정적 글꼴을 실행 시 등록하고, 굵기마다 해당 글꼴 파일(PostScript 이름)을 쓴다.
import CoreText
import SwiftUI

nonisolated enum PumFont {
    static let faces: [(weight: Font.Weight, postScriptName: String)] = [
        (.regular, "Pretendard-Regular"),
        (.medium, "Pretendard-Medium"),
        (.semibold, "Pretendard-SemiBold"),
        (.bold, "Pretendard-Bold"),
        (.heavy, "Pretendard-ExtraBold"),
    ]

    /// 앱 시작 시 한 번. 이미 등록된 글꼴은 건너뛴다. 실패한 파일 이름을 돌려준다.
    @discardableResult
    static func register(bundle: Bundle = .main) -> [String] {
        var failed: [String] = []
        for face in faces {
            guard let url = bundle.url(forResource: face.postScriptName, withExtension: "otf") else {
                failed.append(face.postScriptName)
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let code = (error?.takeRetainedValue()).map { CFErrorGetCode($0) } ?? 0
                if code != CTFontManagerError.alreadyRegistered.rawValue { failed.append(face.postScriptName) }
            }
        }
        return failed
    }

    static func postScriptName(for weight: Font.Weight) -> String {
        faces.first { $0.weight == weight }?.postScriptName ?? "Pretendard-Regular"
    }

    /// 동적 글자 크기를 따르는 Pretendard
    static func font(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) -> Font {
        .custom(postScriptName(for: weight), size: size, relativeTo: style)
    }
}
