//
//  Created by yochidros on 3/21/23
//

import Foundation

public enum LocalStorageManager {
    public static func loads<T: Decodable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([T].self, from: data)
        else {
            return []
        }
        return items
    }

    @discardableResult
    public static func upsert<T: Codable>(_ value: T, key: String, condition: (T, T) -> Bool) -> Bool {
        var items: [T] = loads(key: key)
        if let index = items.firstIndex(where: { condition($0, value) }) {
            items[index] = value
        } else {
            items.append(value)
        }
        guard let data = try? JSONEncoder().encode(items) else { return false }
        UserDefaults.standard.set(data, forKey: key)
        return true
    }
}
