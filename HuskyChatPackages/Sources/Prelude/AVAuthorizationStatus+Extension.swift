//
//  Created by yochidros on 3/21/23
//

import AVFoundation

public extension AVAuthorizationStatus {
    var string: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        @unknown default:
            fatalError()
        }
    }
}
