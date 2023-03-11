//
//  SpeechRecognizer.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import AVFoundation
import Foundation
import Speech

@MainActor class SpeechRecognizerViewModel: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isRecoring: Bool = false
    @Published var text: String = ""
    @Published var isAudioEnabled: Bool = false
    @Published var isRecognitionEnabled: Bool = false

    @Published var lastItemId: String?
    @Published var isSending: Bool = false
    @Published var messages: [Message] = []

    private let recognizer: SFSpeechRecognizer
    private let recoder: AudioRecoder
    private var task: SFSpeechRecognitionTask?

    private let synthesizer = AVSpeechSynthesizer()
    init(recognizer: SFSpeechRecognizer) {
        self.recognizer = recognizer
        recoder = .init()
        isEnabled = recognizer.isAvailable
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
        isEnabled = isAudioEnabled && isRecognitionEnabled
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
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message)
        let voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.voice = voice
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    #if DEBUG
        func debugSend() {
            let text = """
            I went to the shopping mall to buy a movie ticket, even though the movie was not yet released in our country. The movie, called 'Detective Conan', is scheduled to be released this April. I believe it has a serious plot, so I'm excited to watch it as soon as possible.
            """
            let m = Message(
                id: UUID().uuidString.lowercased(),
                role: Bool.random() ? "user" : "assistant",
                message: text
            )
            messages.append(m)
            speak(message: m.message)
            lastItemId = m.id
        }
    #endif

    func send() {
        synthesizer.stopSpeaking(at: .immediate)
        let m = Message(
            id: UUID().uuidString.lowercased(),
            role: "user",
            message: text
        )
        self.messages.append(m)
        let messages = self.messages.map { ($0.role, $0.message) }
        isSending = true
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
        task = recognizer.recognitionTask(with: request) { [weak self] result, err in
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
        isRecoring = true
    }

    func stop() {
        task?.finish()
        isRecoring = false
    }
}

extension SpeechRecognizerViewModel: SFSpeechRecognizerDelegate {
    func speechRecognizer(_: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isEnabled = available
    }
}

extension SpeechRecognizerViewModel: AVSpeechSynthesizerDelegate {}
