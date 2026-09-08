import Foundation

struct FavoritesService {
    private let key = "favorite-page-ids"
    func load(validIDs: Set<String>) -> Set<String> {
        let values = (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
        return Set(values).intersection(validIDs)
    }
    func save(_ ids: Set<String>) { UserDefaults.standard.set(Array(ids).sorted(), forKey: key) }
}
