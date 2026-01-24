import Foundation
import UIKit

enum AIEngine: String, CaseIterable {
    case gemini = "Gemini"
    case chatGPT = "ChatGPT"
}

class AIService {
    // MARK: - Endpoints
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    private let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func sendMessage(text: String, engine: AIEngine, age: String, image: UIImage? = nil) async throws -> String {
        let systemPrompt = "You are a friendly learning assistant for children. Your job is to explain all topics at a 3rd–5th grade level using simple words, short sentences, and a warm, encouraging tone. Always speak as if you are talking to a 9-year-old child. Safety and content rules: Everything you say must be 100% kid-safe. Do not include adult themes, scary or disturbing content, violence, illegal activities, personal information, or sensitive topics. If a child asks about something unsafe or inappropriate, gently say you cannot help with that and guide them to a safe, fun, or educational topic instead. Style rules: Be friendly, kind, and patient. Keep answers short, clear, and easy to understand. Use examples, simple explanations, and positive encouragement. Make learning feel fun and safe. You are always talking to a 9-year-old kid in this conversation."
        
        switch engine {
        case .chatGPT:
            return try await sendToChatGPT(prompt: systemPrompt, userMessage: text, image: image)
        case .gemini:
            return try await sendToGemini(prompt: systemPrompt, userMessage: text, image: image)
        }
    }
    
    // MARK: - ChatGPT Implementation
    private func sendToChatGPT(prompt: String, userMessage: String, image: UIImage?) async throws -> String {
        guard let apiKey = APIKeyManager.getOpenAIKey(), !apiKey.isEmpty else {
            throw NSError(domain: "AIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "OpenAI API Key not found. Please add it in settings."])
        }
        
        guard let url = URL(string: openAIEndpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var userContent: [Any] = [
            ["type": "text", "text": userMessage]
        ]
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
            let base64Image = imageData.base64EncodedString()
            userContent.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(base64Image)"
                ]
            ])
        }
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": prompt],
            ["role": "user", "content": userContent]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 300
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            } else if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                print("ChatGPT API Error: \(message)")
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ChatGPT API Error: \(message)"])
            }
        }
        
        
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unknown"
        print("ChatGPT Raw Response: \(rawResponse)")
        throw NSError(domain: "AIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(rawResponse.prefix(200))"])
    }
    
    // MARK: - Gemini Implementation
    private func sendToGemini(prompt: String, userMessage: String, image: UIImage?) async throws -> String {
        guard let apiKey = APIKeyManager.getGeminiKey(), !apiKey.isEmpty else {
            throw NSError(domain: "AIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Gemini API Key not found. Please add it in settings."])
        }
        
        let urlString = "\(geminiEndpoint)?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Gemini API structure
        var parts: [[String: Any]] = [
            ["text": "\(prompt)\n\nUser Question: \(userMessage)"]
        ]
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
            let base64Image = imageData.base64EncodedString()
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64Image
                ]
            ])
        }
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return text
            } else if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                print("Gemini API Error: \(message)")
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gemini API Error: \(message)"])
            }
        }
        
        let rawResponse = String(data: data, encoding: .utf8) ?? "Unknown"
        print("Gemini Raw Response: \(rawResponse)")
        throw NSError(domain: "AIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(rawResponse.prefix(200))"])
    }
}
