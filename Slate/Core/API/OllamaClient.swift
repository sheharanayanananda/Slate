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

    func generate(prompt: String, image: UIImage) async throws -> String {
        let url = URL(string: "/api/generate", relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer 02bde54ee078433e91088f9973f356f8.6gCblr8J-w_2qcb1ayUv6EQb", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "images": [image.jpegData(compressionQuality: 0.8)!.base64EncodedString()],
            "stream": false,
            "options": [
                "temperature": 0.1,
                "top_p": 0.9,
                "num_predict": 1024
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(OllamaGenerateResponse.self, from: data).response
    }
}
