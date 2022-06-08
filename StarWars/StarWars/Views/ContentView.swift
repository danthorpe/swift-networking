import SwiftUI

struct ContentView {
    @State private var selectedCategory: Category = .planets
}

extension ContentView: View {
    var body: some View {
        NavigationSplitView {
            List(Category.allCases, selection: $selectedCategory) { category in
                NavigationLink(category.localizedName, value: category)
            }
            .navigationTitle("Categories")
        } content: {
            CategoryItems(category: $selectedCategory)
        } detail: {
            Text("Choose something")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
