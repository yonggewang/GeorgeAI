import Foundation

enum AIEngine: String, CaseIterable {
    case gemini = "Gemini"
    case chatGPT = "ChatGPT"
}

class AIService {
    // MARK: - API Keys (Replace with your actual keys)
    private let openAIKey = "OpenAIkey here"
    private let geminiKey = "Gemini key here"
    
    
    // MARK: - Endpoints
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    private let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func sendMessage(text: String, engine: AIEngine, age: String) async throws -> String {
        let systemPrompt = "You are an elementary-school learning assistant. Explain everything at a 3rd–5th grade level using clear, friendly, kid-safe language. All content must be completely appropriate for children. Do not include adult themes, scary or disturbing topics, illegal activities, or personal or sensitive issues. If a user asks about something unsafe, gently refuse and guide them to a safe topic. Keep your responses concise, warm, and detailed enough for children to understand. For this conversation, you are speaking to a kid at the age of \(age)"
        
        switch engine {
        case .chatGPT:
            return try await sendToChatGPT(prompt: systemPrompt, userMessage: text)
        case .gemini:
            return try await sendToGemini(prompt: systemPrompt, userMessage: text)
        }
    }
    
    // MARK: - ChatGPT Implementation
    private func sendToChatGPT(prompt: String, userMessage: String) async throws -> String {
        guard let url = URL(string: openAIEndpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            ["role": "system", "content": prompt],
            ["role": "user", "content": userMessage]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4.1-mini", // Or gpt-4
            "messages": messages,
            "max_tokens": 300 // Limit for concise answers
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
             // Basic error handling for demo
             throw URLError(.cannotParseResponse)
        }
    }
    
    // MARK: - Gemini Implementation
    private func sendToGemini(prompt: String, userMessage: String) async throws -> String {
        let urlString = "\(geminiEndpoint)?key=\(geminiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Gemini API structure
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "\(prompt)\n\nUser Question: \(userMessage)"]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
}
