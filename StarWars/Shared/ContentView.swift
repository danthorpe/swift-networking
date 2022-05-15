import SwiftUI
import HTTP

final class ViewModel: ObservableObject {

    @Published
    var home: StarWars.Home?

    let connection: Connection<StarWars.AppRoute>

    init(_ connection: Connection<StarWars.AppRoute>) {
        self.connection = connection
    }

    @MainActor
    func fetch() async {
        do {
            home = try await connection
                .request(json: .home)
                .body
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
                if let people = viewModel.home?.people {
                    NavigationLink("People") {
                        Text("People")
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
