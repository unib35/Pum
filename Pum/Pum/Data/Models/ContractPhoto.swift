// CloudKit 호환: 모든 속성에 기본값 · Optional, unique 없음, 관계는 Optional + inverse, enum은 원시값으로 저장(iCloud 동기화 조건).
import Foundation
import SwiftData

/// 근로계약서 사진. 이미지는 데이터베이스 밖 파일로 저장(externalStorage) — iCloud에서는 별도 파일(CKAsset)로 올라간다.
@Model
final class ContractPhoto {
    @Attribute(.externalStorage)
    var imageData: Data?
    var createdAt: Date = Date.now

    var employee: Employee?

    init(imageData: Data?, createdAt: Date = .now) {
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
