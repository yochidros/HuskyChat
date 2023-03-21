//
//  Created by yochidros on 3/21/23
//

import Foundation

public struct LocalMessage: Hashable, Codable {
    public let uuid: String
    public var messages: [Message]
    public let date: Date

    public init(uuid: String, messages: [Message], date: Date) {
        self.uuid = uuid
        self.messages = messages
        self.date = date
    }
}
