import Foundation
import Combine

struct FavoriteAction: Equatable {
    let action: String
    let coin: String
}

final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteIds: Set<String> {
        didSet {
            save()
        }
    }
    
    @Published var lastAction: FavoriteAction?
    
    private let key = "crypto_favorites"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.favoriteIds = ids
        } else {
            self.favoriteIds = []
        }
    }
    
    func toggle(_ id: String, coinName: String = "", coinSymbol: String = "") {
        let displayName = coinSymbol.isEmpty ? coinName : coinSymbol.uppercased()
        
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
            lastAction = FavoriteAction(action: "取消收藏", coin: displayName)
        } else {
            favoriteIds.insert(id)
            lastAction = FavoriteAction(action: "已收藏", coin: displayName)
        }
    }
    
    func isFavorite(_ id: String) -> Bool {
        favoriteIds.contains(id)
    }
    
    func add(_ id: String) {
        favoriteIds.insert(id)
    }
    
    func remove(_ id: String) {
        favoriteIds.remove(id)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
