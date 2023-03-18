//
//  SpeechRecognizer.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import AVFoundation
import Foundation
import Speech
extension SFSpeechRecognizerAuthorizationStatus {
    var string: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        @unknown default:
            fatalError()
        }
    }
}

extension AVAuthorizationStatus {
    var string: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        @unknown default:
            fatalError()
        }
    }
}

@MainActor class SpeechRecognizerViewModel: NSObject, ObservableObject {
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
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    var currentDateString: String {
        guard let selectedDate else { return "Today" }
        return formatter.string(from: selectedDate)
    }

    #if os(iOS)
        private var previousCategory: AVAudioSession.Category?
    #endif
    init(recognizer: SFSpeechRecognizer) {
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
        utterance.rate = Float(UserDefaults.standard.double(forKey: "speaker_rate"))
        utterance.pitchMultiplier = Float(UserDefaults.standard.double(forKey: "speaker_pitch"))
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
        LocalMessageManager.add(v)
    }

    private static func addTotalToken(token: Int) -> Int {
        let current = UserDefaults.standard.integer(forKey: "total_token")
        UserDefaults.standard.set(current + token, forKey: "total_token")
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
    func speechRecognizer(_: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isEnabled = available
    }
}

extension SpeechRecognizerViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {
        #if os(iOS)
            previousCategory = AVAudioSession.sharedInstance().category
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt)
        #endif
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        #if os(iOS)
            if let previousCategory {
                try? AVAudioSession.sharedInstance().setCategory(previousCategory)
                self.previousCategory = nil
            }
        #endif
    }
}
