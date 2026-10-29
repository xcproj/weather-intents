import AppIntents
import Foundation
import WeatherShared

/// A place, as the Weather widget's settings list them: the places the app last wrote for the widgets. Here in the
/// widgets' own module (not shared with the app's Siri intents), so the widget's settings metadata can be made by
/// Xcode from a real widget extension, as it would be in an Xcode project (scripts/intents.sh)
struct PlaceEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Place" }
    static var defaultQuery: PlaceQuery { PlaceQuery() }

    /// the place's name and where it is (`WidgetPlace.key`)
    var id: String
    var name: String
    var isHere: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: isHere ? "My location" : nil)
    }

    init(id: String, name: String, isHere: Bool) {
        self.id = id
        self.name = name
        self.isHere = isHere
    }

    init(_ p: WidgetPlace) { self.init(id: p.key, name: p.name, isHere: p.isHere) }
}

struct PlaceQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PlaceEntity] {
        Self.all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [PlaceEntity] { Self.all() }

    func defaultResult() async -> PlaceEntity? { Self.all().first }

    static func all() -> [PlaceEntity] { (WidgetSnapshot.load()?.places ?? []).map(PlaceEntity.init) }
}
