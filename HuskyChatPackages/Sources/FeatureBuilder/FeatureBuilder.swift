//
//  Created by yochidros on 3/21/23
//

import Foundation
import SwiftUI

public protocol FeatureBuilderRequest {}

public protocol FeatureBuilderProtocol {
    func build<Request: FeatureBuilderRequest>(request: Request) -> FeatureScreenView
}

public struct FeatureScreenView: View {
    let view: AnyView

    public init<Content: SwiftUI.View>(view: @escaping () -> Content) {
        self.view = .init(view())
    }

    public var body: some View {
        view
    }
}
