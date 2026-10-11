//
//  ContentView.swift
//  Pum
//
//  Created by 이종민 on 10/11/26.
//

import SwiftUI

/// 아직 기능 화면이 없어 컴포넌트 갤러리를 띄운다. 디자인에 다크 모드 값이 없어 라이트로 고정한다(README 「테마」).
struct ContentView: View {
    var body: some View {
        ComponentGalleryView()
            .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
