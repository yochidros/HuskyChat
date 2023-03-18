//
//  SettingView.swift
//  VoiceToText
//
//  Created by yochidros on 3/18/23.
//

import AVFoundation
import Speech
import SwiftUI

@MainActor class SettingViewModel: ObservableObject {
    @Published var audioStatus: AVAuthorizationStatus = .notDetermined
    @Published var recognitionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @AppStorage(wrappedValue: 0, "total_token")
    var totalToken: Int
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
}

struct SettingView: View {
    @StateObject var viewModel: SettingViewModel = .init()
    var body: some View {
        List {
            Section("Permission") {
                HStack {
                    Text("Audio")
                    Spacer()
                    Text("\(viewModel.audioStatus.string)")
                }
                HStack {
                    Text("Speech Recognition")
                    Spacer()
                    Text("\(viewModel.recognitionStatus.string)")
                }
                Button("Request Permission", action: {
                    viewModel.requestPermission()
                })
                .disabled(!(viewModel.recognitionStatus == .notDetermined && viewModel.audioStatus == .notDetermined))
            }
            Section("Current Price") {
                HStack {
                    Text("token")
                    Spacer()
                    Text("\(viewModel.totalToken)")
                }
                Text("1000 token per $0.02")
                    .foregroundColor(.gray)
                HStack {
                    Text("Current")
                    Spacer()
                    Text("$\(viewModel.totalPrice)")
                }
                Button("Reset", action: {
                    viewModel.resetToken()
                })
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}