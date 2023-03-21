//
//  ChatGPTConversationApp.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import ChatGPTAPIClient
import LocalStorage
import SettingFeature
import SpeechFeature
import SwiftUI

@main
struct HuskyChatApp: App {
    let featureBuilder = FeatureBuilderImpl()
    init() {
        ChatGPTClient.liveApiKey = {
            UserDefaults.standard.string(forKey: UDKeys.apiKey) ?? ""
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                SpeechView(
                    viewModel: .init(
                        recognizer: .init(locale: .init(identifier: "en-US"))!
                    ),
                    featureBuilder: featureBuilder
                )
                #if os(iOS)
                .toolbarBackground(.visible, for: .tabBar)
                #endif
                .tabItem {
                    Image(systemName: "message")
                }
                SettingView()
                #if os(iOS)
                    .toolbarBackground(.visible, for: .tabBar)
                #endif
                    .tabItem {
                        Image(systemName: "gear")
                    }
            }.background(Color.white)
        }
    }
}
