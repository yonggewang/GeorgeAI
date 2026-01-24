import Foundation

enum APIKeyManager {
    private static let openAIKeyKey = "openai_api_key"
    private static let geminiKeyKey = "gemini_api_key"
    
    static func getOpenAIKey() -> String? {
        UserDefaults.standard.string(forKey: openAIKeyKey)
    }
    
    static func getGeminiKey() -> String? {
        UserDefaults.standard.string(forKey: geminiKeyKey)
    }
    
    static func saveOpenAIKey(_ key: String) {
        UserDefaults.standard.set(key.trimmingCharacters(in: .whitespacesAndNewlines), forKey: openAIKeyKey)
    }
    
    static func saveGeminiKey(_ key: String) {
        UserDefaults.standard.set(key.trimmingCharacters(in: .whitespacesAndNewlines), forKey: geminiKeyKey)
    }
    
    static var hasAtLeastOneKey: Bool {
        if let k = getOpenAIKey(), !k.isEmpty { return true }
        if let k = getGeminiKey(), !k.isEmpty { return true }
        return false
    }
}
