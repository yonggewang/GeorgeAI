import SwiftUI

struct TeacherView: View {
    @StateObject private var viewModel = TeacherViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                headerView
                
                Divider()
                
                configurationView
                    .padding(.horizontal)
                
                Divider()
                
                controlsView
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("AI is thinking...")
                }
                
                messageDisplayView
            }
            .navigationBarHidden(true)
            .alert(item: Binding<IdentifiableString?>(
                get: {
                    viewModel.errorMessage.map { IdentifiableString(value: $0) }
                },
                set: { newItem in
                    viewModel.errorMessage = newItem?.value
                }
            )) { error in
                Alert(title: Text("Error"), message: Text(error.value), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        Text("George Wang's AI Teacher")
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top)
    }
    
    private var configurationView: some View {
        VStack(spacing: 12) {
            // Sliders
            HStack {
                VStack {
                    Text("Rate: \(String(format: "%.1f", viewModel.voiceRate))")
                        .font(.caption)
                    Slider(value: $viewModel.voiceRate, in: 0.0...1.0)
                }
                VStack {
                    Text("Pitch: \(String(format: "%.1f", viewModel.voicePitch))")
                        .font(.caption)
                    Slider(value: $viewModel.voicePitch, in: 0.5...2.0)
                }
            }
            
            // Engine Switch
            HStack {
                Text("ChatGPT")
                    .foregroundColor(viewModel.selectedEngine == .chatGPT ? .blue : .gray)
                
                Toggle("", isOn: Binding(
                    get: { viewModel.selectedEngine == .gemini },
                    set: { isGemini in
                        viewModel.selectedEngine = isGemini ? .gemini : .chatGPT
                        // Add notification message to chat
                        let text = isGemini ? "I am the Gemini AI" : "I am the ChatGPT AI"
                        viewModel.messages.append(Message(text: text, isUser: false))
                    }
                ))
                .labelsHidden()
                
                Text("Gemini")
                    .foregroundColor(viewModel.selectedEngine == .gemini ? .blue : .gray)
            }
            
            // Age Input
            HStack {
                Text("Your Age:")
                TextField("Enter age", text: $viewModel.userAge)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Button(action: viewModel.submitAge) {
                    Text("Submit Your Age")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 20) {
            Button(action: viewModel.toggleRecording) {
                HStack {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    Text(viewModel.isRecording ? "Stop & Send" : "Tap to Talk")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.isRecording ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: viewModel.resetConversation) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Conversation")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .disabled(viewModel.isLoading)
    }
    
    private var messageDisplayView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.messages) { msg in
                        HStack {
                            if msg.isUser {
                                Spacer()
                                Text("User: \(msg.text)")
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                            } else {
                                Text("AI: \(msg.text)")
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .id(msg.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages) {
                if let lastMsg = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// Helper for Alert
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}
