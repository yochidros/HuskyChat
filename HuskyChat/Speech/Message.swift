//
//  Message.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation

enum LocalMessageManager {
    static func load() -> [LocalMessage] {
        guard let data = UserDefaults.standard.data(forKey: "local_messages"),
              let items = try? JSONDecoder().decode([LocalMessage].self, from: data)
        else {
            return []
        }
        return items
    }

    static func add(_ message: LocalMessage) {
        var items = load()
        if let index = items.firstIndex(where: { $0.uuid == message.uuid }) {
            items[index].messages = message.messages
        } else {
            items.append(message)
        }
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: "local_messages")
    }
}

struct LocalMessage: Hashable, Codable {
    let uuid: String
    var messages: [Message]
    let date: Date
}

struct Message: Hashable, Sendable, Codable {
    let id: String
    let role: String
    let message: String

    var isAssistant: Bool {
        return role != "user"
    }
}

extension String {
    static var uuid: String {
        UUID().uuidString.lowercased()
    }
}

extension Message {
    static func makeUser(message: String) -> Self {
        .init(id: .uuid, role: "user", message: message)
    }
}
