//
//  ChatGPTConversationApp.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import SwiftUI

@main
struct ChatGPTConversationApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                SpeechView(viewModel: .init(
                    recognizer: .init(locale: .init(identifier: "en-US"))!
                ))
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
