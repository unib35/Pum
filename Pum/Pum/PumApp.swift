//
//  PumApp.swift
//  Pum
//
//  Created by 이종민 on 10/11/26.
//

import SwiftUI

@main
struct PumApp: App {
    init() {
        PumFont.register() // Pretendard (F3)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
