//
//  SettingsViewModel.swift
//  Slate
//
//  Created by Antigravity on 2026-06-14.
//

import SwiftUI
import Observation

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

@Observable
final class SettingsViewModel {
    var apiKey: String = ""
    var selectedModel: String = "gemma4:31b"
    var validationStatus: KeyValidationStatus = .empty
    var models: [String] = []
    var isLoadingModels: Bool = false
    
    private var savedApiKey: String = ""
    private var validationTask: Task<Void, Never>?
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        selectedModel = UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
        
        // Instant load of models from local cache to prevent empty picker rendering lag
        if let cached = UserDefaults.standard.stringArray(forKey: "ollama_available_models") {
            models = cached
        } else {
            models = [selectedModel]
        }
        
        // Read key from Keychain asynchronously to avoid blocking UI during VM init
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
    
    func handleApiKeyChange() {
        validationTask?.cancel()
        
        guard apiKey != savedApiKey else {
            validationStatus = apiKey.isEmpty ? .empty : .valid
            return
        }
        
        validationTask = Task {
            do {
                // Debounce save and validation check by 800ms
                try await Task.sleep(nanoseconds: 800_000_000)
                
                let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Write to Keychain off the main actor to prevent stutters
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
                // Task cancelled
            }
        }
    }
    
    func handleModelChange() {
        let currentSavedModel = UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
        guard selectedModel != currentSavedModel else { return }
        
        UserDefaults.standard.set(selectedModel, forKey: "ollama_model_name")
        
        Task {
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                await performValidation()
            }
        }
    }
    
    func savePendingChanges() {
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
    
    private func performValidation() async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationStatus = .empty
            return
        }
        
        validationStatus = .checking
        
        let client = OllamaClient(modelName: selectedModel, apiKey: trimmed)
        do {
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
        guard !isLoadingModels else { return }
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
            
            var uniqueModels = [selectedModel]
            for name in fetchedNames {
                if !uniqueModels.contains(name) {
                    uniqueModels.append(name)
                }
            }
            
            await MainActor.run {
                self.models = uniqueModels
                UserDefaults.standard.set(uniqueModels, forKey: "ollama_available_models")
            }
        } catch {
            print("Failed to fetch models: \(error)")
        }
    }
}
