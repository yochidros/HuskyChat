//
//  Created by yochidros on 3/21/23
//

import Foundation

public extension String {
    static var uuid: String {
        UUID().uuidString.lowercased()
    }
}
