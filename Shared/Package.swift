// swift-tools-version: 6.0
// the app's WeatherShared, as it is in the app (copied by scripts/intents.sh)
import PackageDescription
let package = Package(
    name: "Shared",
    platforms: [.iOS("17.0")],
    products: [.library(name: "WeatherShared", targets: ["WeatherShared"])],
    targets: [.target(name: "WeatherShared", resources: [.copy("Fonts")], swiftSettings: [.swiftLanguageMode(.v5)])]
)
