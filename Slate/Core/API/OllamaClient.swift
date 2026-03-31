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

final class OllamaClient {
    private let modelName: String
    private let baseURL: URL

    init(
        modelName: String = "gemma3:27b-cloud",
        baseURL: URL = URL(string: "https://ollama.com")!
    ) {
        self.modelName = modelName
        self.baseURL = baseURL
    }

    func generate(prompt: String, system: String? = nil, image: UIImage) async throws -> String {
        let url = URL(string: "/api/generate", relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Secrets.ollamaBearerToken)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "thinking": "low",
            "images": [image.jpegData(compressionQuality: 0.9)!.base64EncodedString()],
            "stream": false,
            "options": [
                "temperature": 0.2,
                "top_p": 0.9,
                "num_predict": 1024
            ]
        ]
        
        if let system = system {
            body["system"] = system
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(OllamaGenerateResponse.self, from: data).response
    }
}
