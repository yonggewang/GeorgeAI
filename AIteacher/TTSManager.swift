import Foundation
import AVFoundation
import Combine

class TTSManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    
    // Rate: 0.0 to 1.0 (Default ~0.5)
    // Pitch: 0.5 to 2.0 (Default 1.0)
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Try to set category - this is critical for physical devices
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            
            // Explicitly override to speaker (critical for iPhone)
            try audioSession.overrideOutputAudioPort(.speaker)
            
            print("✅ TTSManager: Audio session category configured successfully")
            print("   Category: \(audioSession.category.rawValue)")
            print("   Mode: \(audioSession.mode.rawValue)")
            print("   Output volume: \(audioSession.outputVolume)")
            print("   Current route: \(audioSession.currentRoute.outputs.map { $0.portType.rawValue })")
        } catch {
            print("❌ TTSManager: Failed to configure audio session: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
    
    func speak(text: String, rate: Float, pitch: Float) {
        print("🔊 TTSManager: speak() called with text: \(text.prefix(50))...")
        
        // Stop current speech if speaking
        if synthesizer.isSpeaking {
            print("⏹️ TTSManager: Stopping current speech")
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = 1.0  // Ensure maximum volume
        
        print("   Voice: \(utterance.voice?.language ?? "unknown")")
        print("   Rate: \(rate), Pitch: \(pitch), Volume: \(utterance.volume)")
        
        // Activate audio session for playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Re-configure and activate the session
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: [])
            
            // Force audio to speaker (not earpiece)
            try audioSession.overrideOutputAudioPort(.speaker)
            
            print("✅ TTSManager: Audio session activated for playback")
            print("   Current route: \(audioSession.currentRoute.outputs.map { $0.portType.rawValue })")
            print("   Output volume: \(audioSession.outputVolume)")
            
        } catch {
            print("❌ TTSManager: Failed to activate audio session: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }

        print("▶️ TTSManager: Starting speech synthesis...")
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            print("⏹️ TTSManager: stop() called - stopping speech")
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        print("🗣️ TTSManager: Speech started (willSpeakRange)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("✅ TTSManager: Speech synthesis started successfully")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ TTSManager: Speech finished")
        
        // Deactivate audio session after speech finishes
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("   Audio session deactivated")
        } catch {
            print("❌ TTSManager: Failed to deactivate audio session: \(error)")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("⚠️ TTSManager: Speech cancelled")
        
        // Deactivate audio session if speech is cancelled
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("   Audio session deactivated after cancellation")
        } catch {
            print("❌ TTSManager: Failed to deactivate audio session: \(error)")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("⏸️ TTSManager: Speech paused")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("▶️ TTSManager: Speech continued")
    }
}
