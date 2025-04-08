import Foundation
import SwiftUI
import SwiftData

// Define LineItem model
@Model
final class LineItem {
    @Attribute(.unique) var id: UUID
    var order: Int // To keep track of line order in the scene
    var text: String // Will hold transcribed text
    var isUserLine: Bool // true = user line, false = reader line
    var dateCreated: Date
    var audioFilePath: String? // Path to the recorded audio file
    
    // Relationship to parent scene
    @Relationship(inverse: \SceneItem.lines) var scene: SceneItem?
    
    init(order: Int, text: String = "", isUserLine: Bool = true) {
        self.id = UUID()
        self.order = order
        self.text = text
        self.isUserLine = isUserLine
        self.dateCreated = Date()
        self.audioFilePath = nil
    }
}

// Define SceneItem model
@Model
final class SceneItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateCreated: Date
    
    // Relationship to LineItems
    @Relationship(deleteRule: .cascade) var lines: [LineItem] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
    }
} 