//
//  AudioRecorder.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import Foundation
import AVFoundation
import Speech

final class AudioRecoder {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var inputNode: AVAudioInputNode?

    init() {
    }

    func stop() {
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        inputNode = nil
        recognitionRequest = nil
    }

    func prepare(request: SFSpeechAudioBufferRecognitionRequest) {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("error: \(error)")
        }
        #endif
        #if targetEnvironment(simulator)
        return
        #endif

        let _inputNode = audioEngine.inputNode
        inputNode = _inputNode
        self.recognitionRequest = request
        let recordingFormat = _inputNode.outputFormat(forBus: 0)
        _inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print(error)
        }
    }
}
