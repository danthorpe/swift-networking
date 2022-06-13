import SwiftUI

struct ContentView {
//    @State private var selectedResource: Category? = .planets
}

extension ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(Person.localizedTypeName, destination: ResourceList<Person>())
                NavigationLink(Planet.localizedTypeName, destination: ResourceList<Planet>())
            }
            .navigationTitle("Categories")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
