//
//  SFSpeechRecognizer+Extension.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Speech

public extension SFSpeechRecognizer {
    static func requestAuthorizationAsync() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
