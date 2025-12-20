import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool // True if sent by user, False if from AI
    let timestamp = Date()
}
