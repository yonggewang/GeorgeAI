import SwiftUI

struct APIKeySetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var openAIKey: String = ""
    @State private var geminiKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var isSettingsMode: Bool = false
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("This app uses OpenAI’s ChatGPT or Google’s Gemini as its AI backend; therefore, you need to use an API Key from your own ChatGPT or Gemini account.")
                            .font(.body)
                        
                        Text("If you do not have an API Key yet, you can generate one at the following websites:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Link("OpenAI: https://platform.openai.com/api-keys", destination: URL(string: "https://platform.openai.com/api-keys")!)
                                .foregroundColor(.blue)
                            
                            Link("Gemini: aistudio.google.com", destination: URL(string: "https://aistudio.google.com")!)
                                .foregroundColor(.blue)
                            Text("(Select 'Get API Key')")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Simply copy and paste the API Key into the fields below.")
                            .font(.body)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Enter your API Key(s)")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("ChatGPT API Key")
                                .font(.caption)
                            TextField("sk-...", text: $openAIKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Gemini API Key")
                                .font(.caption)
                            TextField("AIza...", text: $geminiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                        }
                    }
                    
                    Button(action: saveKeys) {
                        Text(isSettingsMode ? "Update Keys" : "Save and Begin")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle(isSettingsMode ? "Settings" : "Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: isSettingsMode ? Button("Close") {
                presentationMode.wrappedValue.dismiss()
            } : nil)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Missing Key"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                if let key = APIKeyManager.getOpenAIKey() {
                    openAIKey = key
                }
                if let key = APIKeyManager.getGeminiKey() {
                    geminiKey = key
                }
            }
        }
    }
    
    private func saveKeys() {
        let hasOpenAI = !openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasGemini = !geminiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if !hasOpenAI && !hasGemini {
            alertMessage = "Please enter at least one API Key to continue."
            showAlert = true
            return
        }
        
        // We allow overwriting with empty string if user wants to clear a key (but one must remain)
        APIKeyManager.saveOpenAIKey(openAIKey)
        APIKeyManager.saveGeminiKey(geminiKey)
        
        onSave()
        presentationMode.wrappedValue.dismiss()
    }
}

struct APIKeySetupView_Previews: PreviewProvider {
    static var previews: some View {
        APIKeySetupView(isSettingsMode: false, onSave: {})
    }
}
