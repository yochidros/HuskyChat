//
//  SpeechRecognizer.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import AudioRecoderTools
import AVFoundation
import ChatGPTAPIClient
import Foundation
import LocalStorage
import Message
import Prelude
import Speech

@MainActor public class SpeechRecognizerViewModel: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isRecoring: Bool = false
    @Published var text: String = ""
    @Published var isAudioEnabled: Bool = false
    @Published var isRecognitionEnabled: Bool = false

    @Published var lastItemId: String?
    @Published var isSending: Bool = false
    @Published var messages: [Message] = []
    @Published var totalToken: Int = 0
    @Published var isRecovery: Bool = false

    private let recognizer: SFSpeechRecognizer
    private let recoder: AudioRecoder
    private var task: SFSpeechRecognitionTask?

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUUID: String = .uuid
    @Published var selectedDate: Date?

    var currentDateString: String {
        guard let selectedDate else { return "Today" }
        return DateFormatter.default.string(from: selectedDate)
    }

    #if os(iOS)
        private var previousCategory: AVAudioSession.Category?
    #endif
    public init(recognizer: SFSpeechRecognizer) {
        self.recognizer = recognizer
        recoder = .init()
        isEnabled = recognizer.isAvailable
        super.init()
        self.recognizer.delegate = self
        synthesizer.delegate = self
        checkPermission()
        reset()
    }

    private func reset() {
        currentUUID = .uuid
        selectedDate = nil
        messages = [.init(id: .uuid, role: "system", message: "Recoginition \(SFSpeechRecognizer.authorizationStatus().string)\nAudio \(AVCaptureDevice.authorizationStatus(for: .audio).string)")]
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
        utterance.rate = Float(UserDefaults.standard.double(forKey: UDKeys.speakerRate))
        utterance.pitchMultiplier = Float(UserDefaults.standard.double(forKey: UDKeys.speakerPitch))
        utterance.voice = voice
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func send() {
        synthesizer.stopSpeaking(at: .immediate)
        let m = Message.makeUser(message: text.trimmingCharacters(in: .whitespacesAndNewlines))
        self.messages.append(m)
        let messages = self.messages.filter { $0.role != "system" }.map { ($0.role, $0.message) }
        text = ""
        isSending = true
        Task { @MainActor [weak self] in
            do {
                let res = try await ChatGPTClient.postMessage(messages: messages)
                self?.isSending = false
                guard let r = res.choices.first else {
                    return
                }
                let chatM = Message(id: res.id, role: r.message.role, message: r.message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                self?.totalToken = Self.addTotalToken(token: res.usage.totalTokens)
                self?.messages.append(chatM)
                self?.speak(message: r.message.content)
                self?.save()
            } catch {
                self?.isSending = false
                print(error)
            }
        }
    }

    func newChat() {
        reset()
    }

    func recoveryChat() {
        isRecovery = true
    }

    func didSelectedLocalMessage(_ message: LocalMessage) {
        currentUUID = message.uuid
        messages = message.messages
        selectedDate = message.date
    }

    private func save() {
        let v = LocalMessage(uuid: currentUUID, messages: messages.filter { $0.role != "system" }, date: Date())
        LocalStorageManager.upsert(v, key: UDKeys.localMessage) { base, v in
            base.uuid == v.uuid
        }
    }

    private static func addTotalToken(token: Int) -> Int {
        let current = UserDefaults.standard.integer(forKey: UDKeys.totalToken)
        UserDefaults.standard.set(current + token, forKey: UDKeys.totalToken)
        return current + token
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
    public func speechRecognizer(_: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isEnabled = available
    }
}

extension SpeechRecognizerViewModel: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {
        #if os(iOS)
            previousCategory = AVAudioSession.sharedInstance().category
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt)
        #endif
    }

    public func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        #if os(iOS)
            if let previousCategory {
                try? AVAudioSession.sharedInstance().setCategory(previousCategory)
                self.previousCategory = nil
            }
        #endif
    }
}
