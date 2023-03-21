//
//  File.swift
//
//
//  Created by yochidros on 3/21/23.
//

import AVFoundation
import Foundation
import LocalStorage
import Prelude
import Speech
import SwiftUI

@MainActor class SettingViewModel: ObservableObject {
    @Published var audioStatus: AVAuthorizationStatus = .notDetermined
    @Published var recognitionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @AppStorage(wrappedValue: 0, UDKeys.totalToken)
    var totalToken: Int

    @AppStorage(wrappedValue: 0.5, UDKeys.speakerRate)
    var speakerRate: Double

    @AppStorage(wrappedValue: 1.0, UDKeys.speakerPitch)
    var speakerPitch: Double
    @AppStorage(wrappedValue: "", UDKeys.apiKey)
    var apiKey: String

    var totalPrice: Double {
        (Double(totalToken) / 1000) * 0.02
    }

    init() {
        checkPermission()
    }

    func onAppear() {
        checkPermission()
    }

    func checkPermission() {
        audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        recognitionStatus = SFSpeechRecognizer.authorizationStatus()
    }

    func requestPermission() {
        Task { @MainActor [weak self] in
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            self?.audioStatus = granted ? .authorized : .denied
            let status = await SFSpeechRecognizer.requestAuthorizationAsync()
            self?.recognitionStatus = status
            self?.checkPermission()
        }
    }

    func resetToken() {
        totalToken = 0
    }

    func resetVoiceConfig() {
        speakerRate = 0.5
        speakerPitch = 1.0
    }
}
