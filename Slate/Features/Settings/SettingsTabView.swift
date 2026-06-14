//
//  SettingsTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI

enum KeyValidationStatus: Equatable {
    case empty
    case checking
    case valid
    case invalid(String)
    case limitExceeded
    
    var iconName: String {
        switch self {
        case .empty: return ""
        case .checking: return ""
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .limitExceeded: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .empty: return .clear
        case .checking: return .gray
        case .valid: return .green
        case .invalid: return .red
        case .limitExceeded: return .orange
        }
    }
    
    var message: String {
        switch self {
        case .empty: return ""
        case .checking: return "Checking API key..."
        case .valid: return "Active & Valid"
        case .invalid(let reason): return reason
        case .limitExceeded: return "Usage Limit Exceeded"
        }
    }
}

struct SettingsTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var onDismiss: (() -> Void)? = nil

    @State private var apiKey: String = ""
    @State private var savedApiKey: String = ""
    @State private var selectedModel: String = "gemma4:31b"
    @State private var showKey: Bool = false
    @State private var validationStatus: KeyValidationStatus = .empty
    @State private var models: [String] = []
    @State private var isLoadingModels: Bool = false

    //----------------- Start of UI Code -----------------//
    var body: some View {
        Form {
            Section(
                footer: Text("Your API key is encrypted and stored securely in your device's Keychain. It is used to authorize intelligence features on the cloud server.")
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showKey {
                            TextField("Ollama API Key", text: $apiKey)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Ollama API Key", text: $apiKey)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        
                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if validationStatus != .empty {
                        HStack(spacing: 6) {
                            if validationStatus == .checking {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: validationStatus.iconName)
                                    .foregroundColor(validationStatus.color)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            Text(validationStatus.message)
                                .font(.caption)
                                .foregroundColor(validationStatus.color)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            Section(
                footer: Text("Select the language model that will perform intelligence tasks. The default recommended model is 'gemma4:31b'.")
            ) {
                HStack {
                    Picker("AI Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    
                    if isLoadingModels {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismissView()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Slate")
                    }
                }
            }
        }
        .onAppear {
            loadSettings()
        }
        .task(id: apiKey) {
            // Fast in-memory check against loaded key to avoid synchronous Keychain daemon querying on every keystroke
            guard apiKey != savedApiKey else {
                validationStatus = apiKey.isEmpty ? .empty : .valid
                return
            }
            
            // Debounce save and validation check by 800ms to allow smoother typing
            do {
                try await Task.sleep(nanoseconds: 800_000_000)
                
                let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                await Task(priority: .userInitiated) {
                    if trimmedKey.isEmpty {
                        KeychainHelper.shared.deleteApiKey()
                    } else {
                        KeychainHelper.shared.saveApiKey(trimmedKey)
                    }
                }.value
                
                await MainActor.run {
                    savedApiKey = apiKey
                }
                
                await performValidation()
            } catch {
                // Task cancelled on key change
            }
        }
        .task(id: selectedModel) {
            let currentSavedModel = UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
            guard selectedModel != currentSavedModel else { return }
            
            // Save model immediately to UserDefaults
            UserDefaults.standard.set(selectedModel, forKey: "ollama_model_name")
            
            // Re-validate if API key is not empty
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                await performValidation()
            }
        }
    }
    //----------------- End of UI Code -----------------//

    private func loadSettings() {
        selectedModel = UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
        
        // Instant load of models from local cache to prevent empty picker rendering lag
        if let cached = UserDefaults.standard.stringArray(forKey: "ollama_available_models") {
            models = cached
        } else {
            models = [selectedModel]
        }
        
        // Read key from Keychain asynchronously to avoid blocking popover entry transitions
        Task(priority: .userInitiated) {
            let key = KeychainHelper.shared.readApiKey() ?? ""
            await MainActor.run {
                self.apiKey = key
                self.savedApiKey = key
                if !key.isEmpty {
                    self.validationStatus = .valid
                }
            }
        }
        
        Task {
            await fetchModels()
        }
    }

    private func savePendingChanges() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if apiKey != savedApiKey {
            if trimmedKey.isEmpty {
                KeychainHelper.shared.deleteApiKey()
            } else {
                KeychainHelper.shared.saveApiKey(trimmedKey)
            }
            savedApiKey = apiKey
        }
        
        let currentSavedModel = UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
        if selectedModel != currentSavedModel {
            UserDefaults.standard.set(selectedModel, forKey: "ollama_model_name")
        }
    }
    
    private func dismissView() {
        savePendingChanges()
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func performValidation() async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationStatus = .empty
            return
        }
        
        validationStatus = .checking
        
        let client = OllamaClient(modelName: selectedModel, apiKey: trimmed)
        do {
            // Validation generate check
            _ = try await client.generate(prompt: "", system: "Validation Check", image: nil)
            validationStatus = .valid
        } catch OllamaError.apiError(let message) {
            if message.localizedCaseInsensitiveContains("limit") || message.localizedCaseInsensitiveContains("quota") {
                validationStatus = .limitExceeded
            } else {
                validationStatus = .invalid(message)
            }
        } catch {
            validationStatus = .invalid(error.localizedDescription)
        }
    }

    private func fetchModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        
        guard let url = URL(string: "https://ollama.com/api/tags") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            
            struct TagModel: Decodable {
                let name: String
            }
            struct TagsResponse: Decodable {
                let models: [TagModel]
            }
            
            let tagsRes = try JSONDecoder().decode(TagsResponse.self, from: data)
            let fetchedNames = tagsRes.models.map { $0.name }
            
            await MainActor.run {
                // Filter models to keep only standard, popular prefixes (Gemma, Llama, Phi, Mistral, Qwen)
                // This keeps the SwiftUI Menu Picker lightweight, eliminating list-rendering performance lags.
                let allowedPrefixes = ["gemma", "llama", "phi", "mistral", "qwen"]
                let filteredNames = fetchedNames.filter { name in
                    allowedPrefixes.contains { prefix in
                        name.localizedCaseInsensitiveContains(prefix)
                    }
                }
                
                var uniqueModels = [selectedModel]
                for name in filteredNames {
                    if !uniqueModels.contains(name) {
                        uniqueModels.append(name)
                    }
                }
                self.models = uniqueModels
                // Cache the list of models in UserDefaults
                UserDefaults.standard.set(uniqueModels, forKey: "ollama_available_models")
            }
        } catch {
            print("Failed to fetch models: \(error)")
        }
    }
}

#Preview {
    SettingsTabView()
}
