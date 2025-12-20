import Foundation
import SwiftUI
import Combine

class TeacherViewModel: ObservableObject {
    // MARK: - Services
    private let aiService = AIService()
    private let ttsManager = TTSManager()
    var speechManager = SpeechManager()
    
    // MARK: - Published State
    @Published var messages: [Message] = []
    
    // Configuration
    @Published var voiceRate: Float = 0.5
    @Published var voicePitch: Float = 1.0
    @Published var selectedEngine: AIEngine = .gemini
    @Published var userAge: String = ""
    
    // UI State
    @Published var isRecording: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Sync SpeechManager recording state
        speechManager.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func toggleRecording() {
        if isRecording {
            // Stop recording
            speechManager.stopRecording()
            // Send the finalized transcript
            let text = speechManager.transcript
            if !text.isEmpty {
                sendMessage(text: text)
            }
        } else {
            // Start recording
            do {
                try speechManager.startRecording()
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    func sendMessage(text: String) {
        let newUserMsg = Message(text: text, isUser: true)
        messages.append(newUserMsg)
        
        isLoading = true
        
        Task {
            do {
                let responseText = try await aiService.sendMessage(
                    text: text,
                    engine: selectedEngine,
                    age: userAge
                )
                
                await MainActor.run {
                    let aiMsg = Message(text: responseText, isUser: false)
                    self.messages.append(aiMsg)
                    self.isLoading = false
                    
                    // Speak the response
                    self.ttsManager.speak(text: responseText, rate: self.voiceRate, pitch: self.voicePitch)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "AI Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func resetConversation() {
        messages.removeAll()
        ttsManager.stop()
        
        let welcomeText = "This is George Wang's AI teacher based on OpenAI's ChatGPT and Google's Gemini. This teacher will explain everything at a 3rd to 5th grade level using clear, friendly, kid-safe language. Please ask your questions now."
        
        ttsManager.speak(text: welcomeText, rate: voiceRate, pitch: voicePitch)
    }
    
    func submitAge() {
        // In this app design, age is just stored and used in the prompt.
        // We could verify it's a number, but for now we just accept it.
        // A confirmation toast could be added here if desired.
        print("Age submitted: \(userAge)")
    }
}
