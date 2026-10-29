import CoreText
import Foundation

/// What the widgets show, written by the app after each refresh into the app group's folder, so a widget never asks
/// a weather service for anything the app already knows. Each place: now, today's high and low, the day told in a
/// line, the next hours, and the sky's colours. A widget left alone for over an hour freshens its first place itself,
/// with one small ask (`WidgetFetch`)
public struct WidgetSnapshot: Codable, Sendable {
    public var places: [WidgetPlace]
    public var fahrenheit: Bool
    /// the wind's unit, as the app shows it: "kmh", "mph" or "ms"
    public var speed: String? = nil

    public init(places: [WidgetPlace], fahrenheit: Bool, speed: String? = nil) {
        self.places = places
        self.fahrenheit = fahrenheit
        self.speed = speed
    }

    public static let group = "group.nyc.nikola.weather"

    /// the app group's folder (a sideloaded build's group is renamed by SideStore, which lists it in Info.plist)
    static var folder: URL? {
        let groups = (Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String]) ?? []
        for g in groups + [group] {
            if let u = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: g) { return u }
        }
        return nil
    }

    static var file: URL? { folder?.appendingPathComponent("widgets.json") }

    public static func load() -> WidgetSnapshot? {
        guard let f = file, let d = try? Data(contentsOf: f) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: d)
    }

    public func save() {
        guard let f = Self.file, let d = try? JSONEncoder().encode(self) else { return }
        try? d.write(to: f, options: .atomic)
    }

    public func t(_ c: Double) -> String { "\(Int((fahrenheit ? c * 9 / 5 + 32 : c).rounded()))°" }

    /// a wind speed (km/h) in the app's unit: the number, and the unit's name
    public func wind(_ kmh: Double) -> (String, String) {
        switch speed {
        case "mph": ("\(Int((kmh / 1.609).rounded()))", "mph")
        case "ms": ("\(Int((kmh / 3.6).rounded()))", "m/s")
        default: ("\(Int(kmh.rounded()))", "km/h")
        }
    }

    /// a place by its key, or the first (where you are)
    public func place(_ key: String?) -> WidgetPlace? {
        key.flatMap { k in places.first { $0.key == k } } ?? places.first
    }
}

public struct WidgetPlace: Codable, Sendable, Identifiable {
    public var id: String { name + "\(lat),\(lon)" }
    public var name: String
    public var lat: Double
    public var lon: Double
    public var timeZone: String
    public var isHere: Bool
    public var fetched: Date
    public var temp: Double
    public var feels: Double
    public var high: Double
    public var low: Double
    public var code: Int
    public var isDay: Bool
    /// "Cloudy", "Light snow"
    public var condition: String
    /// the day told in a line, as on the place's page
    public var headline: String
    /// a short rain note for the day ("Rain 2–4pm"), if any
    public var rain: String?
    public var alert: String?
    public var hours: [WidgetHour]
    /// the sky's colours, top and bottom (the app's Colour look)
    public var top: UInt32
    public var bottom: UInt32
    /// the sky's scene and time of day (SkyMood, SkyTime), drawn in dots behind the widget as in the app
    public var mood: String = "day"
    public var time: String = "day"
    /// today's sunrise and sunset, so the sun sits where it is in the sky
    public var sunrise: Date? = nil
    public var sunset: Date? = nil
    /// the next days (the large widget)
    public var days: [WidgetDay] = []
    /// now, for the lock screen's widgets: the UV index (and today's highest), the wind (km/h) and where it's from
    /// (degrees), the US air quality index, and today's rain or snow (mm of water)
    public var uv: Double? = nil
    public var uvMax: Double? = nil
    public var wind: Double? = nil
    public var gust: Double? = nil
    public var windFrom: Double? = nil
    public var aqi: Int? = nil
    public var mmToday: Double? = nil
    public var snowToday: Double? = nil

    public init(name: String, lat: Double, lon: Double, timeZone: String, isHere: Bool, fetched: Date, temp: Double, feels: Double,
                high: Double, low: Double, code: Int, isDay: Bool, condition: String, headline: String, rain: String?, alert: String?,
                hours: [WidgetHour], top: UInt32, bottom: UInt32, mood: String = "day", time: String = "day",
                sunrise: Date? = nil, sunset: Date? = nil, days: [WidgetDay] = [],
                uv: Double? = nil, uvMax: Double? = nil, wind: Double? = nil, gust: Double? = nil, windFrom: Double? = nil,
                aqi: Int? = nil, mmToday: Double? = nil, snowToday: Double? = nil) {
        self.name = name; self.lat = lat; self.lon = lon; self.timeZone = timeZone; self.isHere = isHere; self.fetched = fetched
        self.temp = temp; self.feels = feels; self.high = high; self.low = low; self.code = code; self.isDay = isDay
        self.condition = condition; self.headline = headline; self.rain = rain; self.alert = alert; self.hours = hours
        self.top = top; self.bottom = bottom; self.mood = mood; self.time = time; self.sunrise = sunrise; self.sunset = sunset
        self.days = days
        self.uv = uv; self.uvMax = uvMax; self.wind = wind; self.gust = gust; self.windFrom = windFrom
        self.aqi = aqi; self.mmToday = mmToday; self.snowToday = snowToday
    }

    /// how far through the daylight it is at a moment (0 sunrise, 1 sunset), for the sun's place
    public func daylight(_ d: Date) -> Double? {
        guard let r = sunrise, let s = sunset, s > r else { return nil }
        return d.timeIntervalSince(r) / s.timeIntervalSince(r)
    }

    /// the place as it'll be at a moment: the hour's temperature and sky once that hour comes
    /// the place's name and where it is, as the widgets' settings and Shortcuts know it
    public var key: String { WidgetPlace.key(name: name, lat: lat, lon: lon) }

    public static func key(name: String, lat: Double, lon: Double) -> String {
        "\(name)|\(String(format: "%.3f", lat)),\(String(format: "%.3f", lon))"
    }

    public func at(_ date: Date) -> WidgetPlace {
        guard let h = hours.last(where: { $0.time <= date }), date.timeIntervalSince(fetched) > 30 * 60 else { return self }
        var p = self
        p.temp = h.temp
        p.code = h.code
        p.isDay = h.isDay
        return p
    }
}

public struct WidgetDay: Codable, Sendable, Identifiable {
    public var id: Date { date }
    public var date: Date
    public var high: Double
    public var low: Double
    public var code: Int
    public var chance: Double

    public init(date: Date, high: Double, low: Double, code: Int, chance: Double) {
        self.date = date; self.high = high; self.low = low; self.code = code; self.chance = chance
    }
}

public struct WidgetHour: Codable, Sendable, Identifiable {
    public var id: Date { time }
    public var time: Date
    public var temp: Double
    public var code: Int
    public var isDay: Bool
    public var chance: Double

    public init(time: Date, temp: Double, code: Int, isDay: Bool, chance: Double) {
        self.time = time; self.temp = temp; self.code = code; self.isDay = isDay; self.chance = chance
    }
}

/// a WMO weather code as an SF Symbol (filled, for the widgets' tinted styles)
public func symbol(_ code: Int, day: Bool) -> String {
    switch code {
    case 0: return day ? "sun.max.fill" : "moon.stars.fill"
    case 1, 2: return day ? "cloud.sun.fill" : "cloud.moon.fill"
    case 3: return "cloud.fill"
    case 45, 48: return "cloud.fog.fill"
    case 51...55: return "cloud.drizzle.fill"
    case 56, 57, 66, 67: return "cloud.sleet.fill"
    case 65, 82: return "cloud.heavyrain.fill"
    case 61...64, 80, 81: return "cloud.rain.fill"
    case 71...77, 85, 86: return "cloud.snow.fill"
    case 95...99: return "cloud.bolt.rain.fill"
    default: return "cloud.fill"
    }
}

/// The widgets' own freshening: one small ask to Open-Meteo for the first place (9 variables: one call), when the app
/// hasn't been opened for over an hour
public enum WidgetFetch {
    public static func refresh(_ p: WidgetPlace) async -> WidgetPlace? {
        let lat = (p.lat * 100).rounded() / 100, lon = (p.lon * 100).rounded() / 100
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,weather_code,is_day,uv_index,wind_speed_10m,wind_gusts_10m,wind_direction_10m&hourly=temperature_2m,weather_code,precipitation_probability&daily=temperature_2m_max,temperature_2m_min&forecast_hours=12&forecast_days=1&timeformat=unixtime&timezone=auto") else { return nil }
        var r = URLRequest(url: url)
        r.setValue("omuo-weather-widgets github.com/xcproj/weather-icon", forHTTPHeaderField: "User-Agent")
        r.timeoutInterval = 12
        guard let (d, resp) = try? await URLSession.shared.data(for: r), (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let cur = json["current"] as? [String: Any], let h = json["hourly"] as? [String: Any] else { return nil }
        func num(_ v: Any?) -> Double? { (v as? Double) ?? (v as? Int).map(Double.init) }
        var out = p
        out.fetched = Date()
        out.temp = num(cur["temperature_2m"]) ?? p.temp
        out.feels = num(cur["apparent_temperature"]) ?? p.feels
        out.code = Int(num(cur["weather_code"]) ?? Double(p.code))
        out.isDay = (num(cur["is_day"]) ?? 1) == 1
        out.uv = num(cur["uv_index"]) ?? p.uv
        out.wind = num(cur["wind_speed_10m"]) ?? p.wind
        out.gust = num(cur["wind_gusts_10m"]) ?? p.gust
        out.windFrom = num(cur["wind_direction_10m"]) ?? p.windFrom
        if let d = json["daily"] as? [String: Any] {
            out.high = num((d["temperature_2m_max"] as? [Any])?.first) ?? p.high
            out.low = num((d["temperature_2m_min"] as? [Any])?.first) ?? p.low
        }
        let times = (h["time"] as? [Any])?.compactMap(num) ?? []
        let temps = (h["temperature_2m"] as? [Any]) ?? [], codes = (h["weather_code"] as? [Any]) ?? []
        let pops = (h["precipitation_probability"] as? [Any]) ?? []
        out.hours = times.indices.map { i in
            WidgetHour(time: Date(timeIntervalSince1970: times[i]), temp: num(temps[safe: i]) ?? 0, code: Int(num(codes[safe: i]) ?? 0),
                       isDay: out.isDay, chance: num(pops[safe: i]) ?? 0)
        }
        return out
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

/// the dot font (NDOT 47), for the widgets' temperatures
public enum WidgetFonts {
    public static let dots = "NDOT47inspiredbyNOTHING"
    nonisolated(unsafe) private static var done = false

    public static func register() {
        guard !done, let url = Bundle.module.url(forResource: "NDot47", withExtension: "otf", subdirectory: "Fonts") else { return }
        done = true
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
