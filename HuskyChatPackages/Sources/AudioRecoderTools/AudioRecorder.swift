//
//  AudioRecorder.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import AVFoundation
import Foundation
import Speech

public final class AudioRecoder {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var inputNode: AVAudioInputNode?

    #if os(iOS)
        private var previousCategory: AVAudioSession.Category?
    #endif
    public init() {}

    public func stop() {
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        inputNode = nil
        recognitionRequest = nil
        #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            do {
                if let previousCategory {
                    try session.setCategory(previousCategory)
                }
                try session.setActive(false)
                previousCategory = nil
            } catch {
                print("error: \(error)")
            }
        #endif
    }

    public func prepare(request: SFSpeechAudioBufferRecognitionRequest) {
        #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            previousCategory = session.category
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
        recognitionRequest = request
        let recordingFormat = _inputNode.outputFormat(forBus: 0)
        _inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
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
