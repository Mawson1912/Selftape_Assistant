import Foundation
import SwiftUI
import SwiftData

@Model
final class SceneItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateCreated: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
    }
} 