import Networking
import SwiftUI

final class PeopleViewModel: ObservableObject {

    @Published
    var people: [StarWarsAPI.Person] = []

    @Published
    var peopleResponse: StarWarsAPI.People?

    @MainActor
    func fetch() async {
        do {
            peopleResponse = try await connection
                .value(for: .api(.people(.home)), decoder: decoder)
                .body
            let peopleToAppend = (peopleResponse?.results ?? [])
//                .filter { people.contains($0) }
            if people.count < peopleToAppend.count {
                people.append(contentsOf: peopleToAppend)
            }
        } catch {
            print("Error fetching people: \(error)")
        }
    }
}

struct PeopleView {
    @ObservedObject var viewModel: PeopleViewModel

    init(viewModel: PeopleViewModel) {
        self.viewModel = viewModel
    }
}

extension PeopleView: View {
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.people, id: \.self) { person in
                Text(person.name)
            }
        }
        .task {
            await viewModel.fetch()
        }
    }
}

struct PeopleView_Previews: PreviewProvider {
    static var previews: some View {
        PeopleView(viewModel: .init())
    }
}
