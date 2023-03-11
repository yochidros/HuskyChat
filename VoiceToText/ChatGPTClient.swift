//
//  ChatGPTClient.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation

enum ChatGPTClient {
    static let apiKey = ""
    static let url = URL(string: "https://api.openai.com/v1/chat/completions")!

    static func postMessage(messages: [(String, String)]) async throws -> ChatMessageResponse {

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Self.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(ChatMessagePayload(messages: messages.map({ ChatMessage(role: $0.0, content: $0.1 )})))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let r = response as? HTTPURLResponse, (200..<300).contains(r.statusCode) else { throw ClientError.badRequest }
        let message = try JSONDecoder().decode(ChatMessageResponse.self, from: data)
        return message
    }
    enum ClientError: Error {
        case badRequest
    }
}

struct ChatMessagePayload: Encodable {
    let model: String = "gpt-3.5-turbo"
    let messages: [ChatMessage]
    init(messages: [ChatMessage]) {
        self.messages = messages
    }
}
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatMessageResponse: Decodable {
    let id: String
    let created: Int
    let choices: [ChatMessageChoiceResponse]
}
struct ChatMessageChoiceResponse: Decodable {
    let index: Int
    let message: ChatMessage
}
