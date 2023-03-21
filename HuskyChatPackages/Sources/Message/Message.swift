//
//  Message.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation
import Prelude

public struct Message: Hashable, Sendable, Codable {
    public let id: String
    public let role: String
    public let message: String

    public var isAssistant: Bool {
        return role != "user"
    }

    public init(id: String, role: String, message: String) {
        self.id = id
        self.role = role
        self.message = message
    }
}

public extension Message {
    static func makeUser(message: String) -> Self {
        .init(id: .uuid, role: "user", message: message)
    }
}
