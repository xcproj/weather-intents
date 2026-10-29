import AppIntents

/// What Siri answers without any setting up ("Will it rain today in omuo weather?"), and what Shortcuts and Spotlight
/// list. (App Store Connect turns away phrases without the app's name in them)
public struct WeatherShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RainTodayIntent(), phrases: [
            "Will it rain today in \(.applicationName)",
            "Is it going to rain in \(.applicationName)",
            "Do I need an umbrella in \(.applicationName)",
        ], shortTitle: "Will It Rain?", systemImageName: "cloud.rain")
        AppShortcut(intent: WeatherNowIntent(), phrases: [
            "What's the weather in \(.applicationName)",
            "\(.applicationName) weather now",
        ], shortTitle: "Weather Now", systemImageName: "thermometer.medium")
        AppShortcut(intent: OpenPlaceIntent(), phrases: [
            "Open \(\.$place) in \(.applicationName)",
            "Show \(\.$place) in \(.applicationName)",
        ], shortTitle: "Open Place", systemImageName: "location")
    }
}
