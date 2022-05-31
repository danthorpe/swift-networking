import Networking
import SwiftUI

final class ViewModel: ObservableObject {

    @Published
    var home: StarWarsAPI.Home?

    let connection: Connection<StarWarsAPI.AppRoute>

    init(_ connection: Connection<StarWarsAPI.AppRoute>) {
        self.connection = connection
    }

    @MainActor
    func fetch() async {        
        do {
            home = try await connection
                .value(for: .api(.home), decoder: JSONDecoder())
                .value
        } catch {
            print("Error fetching home: \(error)")
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            VStack {
                if let _ = viewModel.home?.people {
                    NavigationLink("People") {
                        PeopleView(viewModel: .init(viewModel.connection))
                    }
                }
                if let planets = viewModel.home?.planets {
                    NavigationLink("Planets") {
                        Text("Planets")
                    }
                }
            }
            .navigationTitle("Star Wars")
        }
        .task {
            await viewModel.fetch()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            viewModel: .init(connection)
        )
    }
}
