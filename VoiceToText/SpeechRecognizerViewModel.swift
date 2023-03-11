//
//  SpeechRecognizer.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation
import Speech
import AVFoundation

struct Message: Hashable, Sendable {
    let id: String
    let role: String
    let message: String

    var isAssistant: Bool {
        return role == "assistant"
    }
}
@MainActor class SpeechRecognizerViewModel: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isRecoring: Bool = false
    @Published var text: String = ""
    @Published var isAudioEnabled: Bool = false
    @Published var isRecognitionEnabled: Bool = false

    @Published var isSending: Bool = false
    @Published var messages: [Message] = []

    private let recognizer: SFSpeechRecognizer
    private let recoder: AudioRecoder
    private var task: SFSpeechRecognitionTask?

    private let synthesizer = AVSpeechSynthesizer()
    init(recognizer: SFSpeechRecognizer) {
        self.recognizer = recognizer
        self.recoder = .init()
        self.isEnabled = recognizer.isAvailable
        super.init()
        self.recognizer.delegate = self
        checkPermission()
    }
    func checkPermission() {
        if case .authorized = AVCaptureDevice.authorizationStatus(for: .audio) {
            self.isAudioEnabled = true
        }
        if case .authorized = SFSpeechRecognizer.authorizationStatus() {
            self.isRecognitionEnabled = true
        }
        self.isEnabled = isAudioEnabled && isRecognitionEnabled
    }

    func requestPermission() {
        Task { @MainActor [weak self] in
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            self?.isAudioEnabled = granted
            let status = await SFSpeechRecognizer.requestAuthorizationAsync()
            switch status {
            case .notDetermined, .denied, .restricted:
                self?.isRecognitionEnabled = false
            case .authorized:
                self?.isRecognitionEnabled = true
            @unknown default:
                fatalError()
            }
            self?.checkPermission()
        }
    }
    func speak(message: String) {
        let utterance = AVSpeechUtterance(string: message)
        let voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.voice = voice
        utterance.volume = 1.0
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        synthesizer.continueSpeaking()
    }

    func send() {
        let m = Message(
            id: UUID().uuidString.lowercased(),
            role: "user",
            message: text
        )
        self.messages.append(m)
        let messages = self.messages.map({ ($0.role, $0.message) })
        self.isSending = true
        Task { @MainActor [weak self] in
            do {
                let res = try await ChatGPTClient.postMessage(messages: messages)
                self?.isSending = false
                guard let r = res.choices.first else {
                    return
                }
                let chatM = Message(id: res.id, role: r.message.role, message: r.message.content)
                self?.messages.append(chatM)
                self?.speak(message: r.message.content)
            } catch {
                self?.isSending = false
                print(error)
            }
        }
    }

    func record() {
        text = ""
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recoder.prepare(request: request)
        self.task = recognizer.recognitionTask(with: request) { [weak self] result, err in
            var isFinal = false
            if let result {
                isFinal = result.isFinal
                self?.text = result.bestTranscription.formattedString
            }
            if err != nil || isFinal {
                self?.isRecoring = false
                self?.recoder.stop()
                self?.task = nil
            }
        }
        self.isRecoring = true
    }
    func stop() {
        self.task?.finish()
        self.isRecoring = false
    }
}
extension SpeechRecognizerViewModel: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.isEnabled = available
    }
}
extension SpeechRecognizerViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        print(utterance)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print(utterance)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print(utterance)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print(utterance)
    }
}
