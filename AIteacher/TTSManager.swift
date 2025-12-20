import Foundation
import AVFoundation
import Combine

class TTSManager: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    // Rate: 0.0 to 1.0 (Default ~0.5)
    // Pitch: 0.5 to 2.0 (Default 1.0)
    
    func speak(text: String, rate: Float, pitch: Float) {
        // Stop current speech if speaking
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
