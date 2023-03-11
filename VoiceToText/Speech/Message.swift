//
//  Message.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation

struct Message: Hashable, Sendable {
    let id: String
    let role: String
    let message: String

    var isAssistant: Bool {
        return role == "assistant"
    }
}
