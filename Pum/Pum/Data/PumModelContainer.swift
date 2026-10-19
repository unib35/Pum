import Foundation
import SwiftData

/// 앱 저장소(DEC-030: SwiftData 기기 저장 + iCloud 백업, 서버 · 로그인 없음).
enum PumModelContainer {
    static let modelTypes: [any PersistentModel.Type] = [
        Workplace.self, Employee.self, WorkTerms.self, WorkDay.self,
        PayrollMonth.self, Payslip.self, ContractPhoto.self,
    ]

    static var schema: Schema { Schema(modelTypes) }

    /// 실제 앱용. iCloud(CloudKit) 권한이 있으면 개인 데이터베이스와 동기화하고, 없으면 기기에만 저장한다.
    static func makeShared() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// 테스트 · 미리보기용 메모리 저장(iCloud 끔).
    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
