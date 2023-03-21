//
//  ChatGPTClient.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation

public enum ChatGPTClient {
    public static var liveApiKey: () -> String = { "" }
    static let url = URL(string: "https://api.openai.com/v1/chat/completions")!

    public static func postMessage(messages: [(String, String)]) async throws -> ChatMessageResponse {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Self.liveApiKey())", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(ChatMessagePayload(messages: messages.map { ChatMessage(role: $0.0, content: $0.1) }))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let r = response as? HTTPURLResponse, (200 ..< 300).contains(r.statusCode) else { throw ClientError.badRequest }
        let message = try JSONDecoder().decode(ChatMessageResponse.self, from: data)
        return message
    }

    public enum ClientError: Error {
        case badRequest
    }
}

public struct ChatMessagePayload: Encodable {
    public let model: String = "gpt-3.5-turbo"
    public let messages: [ChatMessage]

    public init(messages: [ChatMessage]) {
        self.messages = messages
    }
}

public struct ChatMessage: Codable {
    public let role: String
    public let content: String
}

public struct ChatMessageResponse: Decodable {
    public let id: String
    public let created: Int
    public let usage: ChatUsageResponse
    public let choices: [ChatMessageChoiceResponse]

    public init(id: String, created: Int, usage: ChatUsageResponse, choices: [ChatMessageChoiceResponse]) {
        self.id = id
        self.created = created
        self.usage = usage
        self.choices = choices
    }
}

public struct ChatUsageResponse: Decodable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

public struct ChatMessageChoiceResponse: Decodable {
    public let index: Int
    public let message: ChatMessage
}
