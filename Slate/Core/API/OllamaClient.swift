//
//  OllamaClient.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-28.
//

import Foundation
import UIKit

struct OllamaGenerateResponse: Decodable {
    let response: String
}

enum OllamaError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Ollama API Key is missing. Please go to the Settings popover in the Slate tab to configure it."
        case .invalidResponse:
            return "Invalid response from the server."
        case .apiError(let message):
            return message
        }
    }
}

final class OllamaClient {
    private let modelName: String
    private let apiKey: String?
    private let baseURL: URL

    init(
        modelName: String? = nil,
        apiKey: String? = nil,
        baseURL: URL = URL(string: "https://ollama.com")!
    ) {
        self.modelName = modelName ?? UserDefaults.standard.string(forKey: "ollama_model_name") ?? "gemma4:31b"
        self.apiKey = apiKey ?? KeychainHelper.shared.readApiKey()
        self.baseURL = baseURL
    }

    func generate(prompt: String, system: String? = nil, image: UIImage? = nil) async throws -> String {
        guard let resolvedKey = apiKey, !resolvedKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OllamaError.missingAPIKey
        }
        
        let url = URL(string: "/api/generate", relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resolvedKey)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.2,
                "top_p": 0.9,
                "num_predict": 1024
            ]
        ]
        
        if let image = image, let jpegData = image.jpegData(compressionQuality: 0.75) {
            body["images"] = [jpegData.base64EncodedString()]
            body["thinking"] = "low"
        }
        
        if let system = system {
            body["system"] = system
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                throw OllamaError.apiError("Unauthorized: The API Key is incorrect or inactive.")
            } else if httpResponse.statusCode == 429 {
                throw OllamaError.apiError("Usage Limit Exceeded: You have reached your weekly Ollama usage limit.")
            } else if httpResponse.statusCode != 200 {
                if let errObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errMsg = errObj["error"] as? String {
                    throw OllamaError.apiError(errMsg)
                }
                throw OllamaError.apiError("API Error: HTTP Status \(httpResponse.statusCode)")
            }
        }
        
        do {
            return try JSONDecoder().decode(OllamaGenerateResponse.self, from: data).response
        } catch {
            throw OllamaError.invalidResponse
        }
    }
}
