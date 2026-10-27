import Foundation
import SwiftData

@Model
final class MediaCollection {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    init(name: String, id: UUID = UUID()) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
    }
}
