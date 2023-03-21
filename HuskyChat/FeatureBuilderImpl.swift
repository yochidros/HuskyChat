//
//  Created by yochidros on 3/21/23
//

import FeatureBuilder
import Foundation
import RecoveryChatFeatureBuilder
import RecoveryChatFeature

final class FeatureBuilderImpl: FeatureBuilderProtocol {
    @MainActor func build<Request>(request: Request) -> FeatureScreenView where Request: FeatureBuilderRequest {
        switch request {
        case let r as RecoveryChatFeatureRequest:
            return FeatureScreenView {
                RecoveryChatViewBuilder.build(selectedMessageHandler: r.completion)
            }
        default:
            fatalError()
        }
    }
}
