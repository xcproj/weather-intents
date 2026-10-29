import AppIntents
import Foundation
import WeatherShared

/// "Will it rain today?": the day's line, the way the app tells it ("Sunny w/ 80% chance of rain from 2pm to 4pm")
public struct RainTodayIntent: AppIntent {
    public static var title: LocalizedStringResource = "Will It Rain Today?"
    public static var description = IntentDescription("Tells you whether it'll rain today, and when, the way omuo weather reads the day.")

    @Parameter(title: "Place") public var place: PlaceEntity?

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        guard let s = WidgetSnapshot.load(), let p = s.place(place?.id) else {
            return .result(value: "", dialog: "Open omuo weather once so it can check the forecast.")
        }
        let line = p.rain.map { "\($0) in \(p.name). \(p.headline)" } ?? "\(p.headline) in \(p.name)."
        let words = p.alert.map { "\(line) There's a \($0)." } ?? line
        return .result(value: words, dialog: "\(words)")
    }
}

/// "What's the weather?": now, and the day's high and low
public struct WeatherNowIntent: AppIntent {
    public static var title: LocalizedStringResource = "Current Weather"
    public static var description = IntentDescription("The temperature and sky now, and today's high and low.")

    @Parameter(title: "Place") public var place: PlaceEntity?

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        guard let s = WidgetSnapshot.load(), let p = s.place(place?.id)?.at(Date()) else {
            return .result(value: "", dialog: "Open omuo weather once so it can check the forecast.")
        }
        let words = "It's \(s.t(p.temp)) and \(p.condition.lowercased()) in \(p.name), feeling like \(s.t(p.feels)). Today's high is \(s.t(p.high)), the low \(s.t(p.low))."
        return .result(value: words, dialog: "\(words)")
    }
}

/// opens the app on a place
public struct OpenPlaceIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Place"
    public static var description = IntentDescription("Opens omuo weather on one of your places.")
    public static var openAppWhenRun = true

    @Parameter(title: "Place") public var place: PlaceEntity

    public init() {}

    public init(place: PlaceEntity) { self.place = place }

    @MainActor
    public func perform() async throws -> some IntentResult {
        IntentBridge.open?(place.id)
        return .result()
    }
}
