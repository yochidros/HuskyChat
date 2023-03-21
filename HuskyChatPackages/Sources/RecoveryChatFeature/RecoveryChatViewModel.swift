//
//  Created by yochidros on 3/21/23
//

import Foundation
import LocalStorage
import Message

@MainActor class RecoveryChatViewModel: ObservableObject {
    @Published var localMessages: [LocalMessage] = []
    private let selectedMessageHandler: (LocalMessage) -> Void

    init(
        selectedMessageHandler: @escaping (LocalMessage) -> Void
    ) {
        self.selectedMessageHandler = selectedMessageHandler

        load()
    }

    private func load() {
        localMessages = LocalStorageManager.loads(key: UDKeys.localMessage)
    }

    func selectMessage(_ message: LocalMessage) {
        selectedMessageHandler(message)
    }
}
