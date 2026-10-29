import AppIntents
import WidgetKit

/// What a widget shows (picked in its settings: touch and hold it, Edit Widget)
public enum WidgetShow: String, AppEnum {
    case now, hours, days, rain, sun, line

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Show" }
    public static var caseDisplayRepresentations: [WidgetShow: DisplayRepresentation] {
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
public struct PlaceWidgetIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Weather"
    public static var description = IntentDescription("Pick the place and what the widget shows.")

    @Parameter(title: "Place", description: "Leave empty for where you are") public var place: PlaceEntity?
    @Parameter(title: "Show", default: .hours) public var show: WidgetShow

    public init() {}

    public init(place: PlaceEntity?, show: WidgetShow) {
        self.place = place
        self.show = show
    }
}
