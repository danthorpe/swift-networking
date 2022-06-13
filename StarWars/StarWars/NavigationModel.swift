import Foundation

final class NavigationModel: ObservableObject, Codable {
    enum CodingKeys: String, CodingKey {
        case selectedCategory
    }

    @Published var selectedCategory: Category = .people

    init() { }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.selectedCategory = try container.decode(Category.self, forKey: .selectedCategory)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedCategory, forKey: .selectedCategory)
    }
}
