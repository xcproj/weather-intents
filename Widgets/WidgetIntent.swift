import AppIntents
import WidgetKit

// (in the widgets' own module: see WidgetPlaces.swift)

/// What a widget shows (picked in its settings: touch and hold it, Edit Widget)
enum WidgetShow: String, AppEnum {
    case now, hours, days, rain, sun, line

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Show" }
    static var caseDisplayRepresentations: [WidgetShow: DisplayRepresentation] {
        [
            .now: "Now",
            .hours: "Next hours",
            .days: "Next days",
            .rain: "Rain",
            .sun: "Sun and moon",
            .line: "The day in a line",
        ]
    }
}

/// a widget's settings: which place (or where you are), and what it shows
struct PlaceWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Weather"
    static var description = IntentDescription("Pick the place and what the widget shows.")

    @Parameter(title: "Place", description: "Leave empty for where you are") var place: PlaceEntity?
    @Parameter(title: "Show", default: .now) var show: WidgetShow

    init() {}

    init(place: PlaceEntity?, show: WidgetShow) {
        self.place = place
        self.show = show
    }
}
