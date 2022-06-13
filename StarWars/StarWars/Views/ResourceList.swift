import SwiftUI

struct ResourceList<Resource: StarWarsResource> {
    @StateObject var repository = DataRepository.live
}

extension ResourceList: View {
    var body: some View {
        content
            .listStyle(.plain)
            .navigationTitle(Resource.localizedTypeName)
            .task {
                do {
                    try await repository.fetch(resource: Resource.self)
                }
                catch {
                    // TODO
                }
            }
    }

    @ViewBuilder
    var content: some View {
        switch Resource.self {
        case is Person.Type:
            List(repository.people) { item in
                Text(item.name)
                    .task {
                        do { try await repository.fetchMore(of: item) }
                        catch { }
                    }
            }
        case is Planet.Type:
            List(repository.planets) { item in
                Text(item.name)
                    .task {
                        do { try await repository.fetchMore(of: item) }
                        catch { }
                    }
            }

        default:
            EmptyView()
        }
    }
}

struct ResourceList_Previews: PreviewProvider {
    static var previews: some View {
        ResourceList<Person>()
    }
}
