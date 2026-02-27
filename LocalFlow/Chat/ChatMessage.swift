import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    let timestamp: Date = .now

    enum Role { case user, assistant }
}
