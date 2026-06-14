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

    @State private var apiKey: String = ""
    @State private var selectedModel: String = "gemma4:31b"
    @State private var showKey: Bool = false
    @State private var validationStatus: KeyValidationStatus = .empty
    @State private var models: [String] = []
    @State private var isLoadingModels: Bool = false

    //----------------- Start of UI Code -----------------//
    var body: some View {
        Form {
            Section(
                footer: Text("Your API key is encrypted and stored securely in your device's Keychain. It is used to authorize intelligence features (such as Smart Lense) on the cloud server.")
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSettings()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            loadSettings()
        }
        .task(id: apiKey) {
            // Debounce validation check by 0.6 seconds
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
                await performValidation()
            } catch {
                // Task cancelled on key change
            }
        }
    }
    //----------------- End of UI Code -----------------//

    private func loadSettings() {
        apiKey = KeychainHelper.shared.readApiKey() ?? ""
        selectedModel = UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
        models = [selectedModel]
        
        Task {
            await fetchModels()
        }
    }

    private func saveSettings() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty {
            KeychainHelper.shared.deleteApiKey()
        } else {
            KeychainHelper.shared.saveApiKey(trimmedKey)
        }
        UserDefaults.standard.set(selectedModel, forKey: "ollama_model_name")
        dismiss()
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
                var uniqueModels = [selectedModel]
                for name in fetchedNames {
                    if !uniqueModels.contains(name) {
                        uniqueModels.append(name)
                    }
                }
                self.models = uniqueModels
            }
        } catch {
            print("Failed to fetch models: \(error)")
        }
    }
}

#Preview {
    SettingsTabView()
}
