//
//  PumApp.swift
//  Pum
//
//  Created by 이종민 on 10/11/26.
//

import SwiftData
import SwiftUI

@main
struct PumApp: App {
    private let container: ModelContainer

    init() {
        PumFont.register() // Pretendard (F3)
        do {
            container = try PumModelContainer.makeShared()
        } catch {
            fatalError("저장소를 열 수 없어요: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
