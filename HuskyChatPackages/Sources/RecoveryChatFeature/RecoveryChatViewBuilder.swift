//
//  RecoveryChatView.swift
//  HuskyChat
//
//  Created by yochidros on 3/18/23.
//

import Message
import SwiftUI

public enum RecoveryChatViewBuilder {
    @MainActor public static func build(
        selectedMessageHandler: @escaping (LocalMessage) -> Void
    ) -> RecoveryChatView {
        let vm = RecoveryChatViewModel(selectedMessageHandler: selectedMessageHandler)
        return RecoveryChatView(viewModel: vm)
    }
}
