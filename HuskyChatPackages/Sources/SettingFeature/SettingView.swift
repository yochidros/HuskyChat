//
//  Created by yochidros on 3/21/23
//

import Foundation
import Prelude
import SwiftUI

public struct SettingView: View {
    @StateObject var viewModel: SettingViewModel = .init()
    public init() {}
    public var body: some View {
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
            Section("API Key") {
                SecureField("", text: $viewModel.apiKey)
                Button("hide keyboard", action: {
                    UIApplication.shared.endEditing()
                })
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
                Button("Reset Price Calcurate", action: {
                    viewModel.resetToken()
                })
            }
            Section("Speaker Voice") {
                HStack {
                    Text("Rate")
                    Slider(value: $viewModel.speakerRate, in: 0.1 ... 1.0, step: 0.1)
                }
                HStack {
                    Text("Picth")
                    Slider(value: $viewModel.speakerPitch, in: 0.5 ... 2.0, step: 0.1)
                }
                Button("Reset Voice Config", action: {
                    viewModel.resetVoiceConfig()
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
