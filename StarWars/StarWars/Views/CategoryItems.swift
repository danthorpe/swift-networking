import SwiftUI

struct CategoryItems {
    @Binding var category: Category
    @StateObject var repository = DataRepository.live
}

extension CategoryItems: View {
    var body: some View {
        content
            .navigationTitle(category.localizedName)
            .task {
                do {
                    try await repository.fetch(category: category)
                }
                catch {
                    // TODO
                }
            }
    }

    @ViewBuilder
    var content: some View {
        switch category {
        case .people:
            List(repository.people) { item in
                Text(item.name)
            }
        case .planets:
            List(repository.planets) { item in
                Text(item.name)
            }
        default:
            Text("\(category.localizedName)")
        }
    }
}

struct CategoryItems_Previews: PreviewProvider {
    static var previews: some View {
        CategoryItems(category: .constant(.people))
    }
}
