//
//  Created by yochidros on 3/21/23
//

import Foundation

import FeatureBuilder
import Message

public struct RecoveryChatFeatureRequest: FeatureBuilderRequest {
    public let completion: (LocalMessage) -> Void
    public init(completion: @escaping (LocalMessage) -> Void) {
        self.completion = completion
    }
}
