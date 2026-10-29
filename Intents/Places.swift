import AppIntents
import Foundation
import WeatherShared

/// What Siri, Shortcuts and the widgets' settings know of omuo weather: its places, and how to answer about them, all
/// from what the app last wrote for the widgets (WidgetSnapshot), so asking costs no forecast call. Its metadata
/// (Metadata.appintents, which Siri and Shortcuts read) is made by Xcode on a GitHub Mac, from these same files, in
/// the private repo xcproj/weather-intents (scripts/intents.sh)

/// A place, as Shortcuts and the widgets' settings see it
public struct PlaceEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Place" }
    public static var defaultQuery: PlaceQuery { PlaceQuery() }

    /// the place's name and where it is (`WidgetPlace.key`)
    public var id: String
    public var name: String
    public var isHere: Bool

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: isHere ? "My location" : nil)
    }

    public init(id: String, name: String, isHere: Bool) {
        self.id = id
        self.name = name
        self.isHere = isHere
    }

    init(_ p: WidgetPlace) { self.init(id: p.key, name: p.name, isHere: p.isHere) }
}

public struct PlaceQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [PlaceEntity] {
        Self.all().filter { identifiers.contains($0.id) }
    }

    public func suggestedEntities() async throws -> [PlaceEntity] { Self.all() }

    public func defaultResult() async -> PlaceEntity? { Self.all().first }

    static func all() -> [PlaceEntity] { (WidgetSnapshot.load()?.places ?? []).map(PlaceEntity.init) }
}

extension WidgetSnapshot {
    /// a place by its key, or the first (where you are)
    public func place(_ key: String?) -> WidgetPlace? {
        key.flatMap { k in places.first { $0.key == k } } ?? places.first
    }
}

/// How an intent reaches the app (this module can't see it): set as soon as the app starts
@MainActor
public enum IntentBridge {
    /// show a place (by its key)
    public static var open: ((String) -> Void)?
}
