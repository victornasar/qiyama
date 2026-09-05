import Adhan
import Foundation

enum Prayer {
    static func params(for method: CalculationMethodId) -> CalculationParameters {
        switch method {
        case .isna: return CalculationMethod.northAmerica.params
        case .mwl: return CalculationMethod.muslimWorldLeague.params
        case .egyptian: return CalculationMethod.egyptian.params
        case .ummAlQura: return CalculationMethod.ummAlQura.params
        case .karachi: return CalculationMethod.karachi.params
        }
    }

    static func fajr(
        for date: Date,
        latitude: Double,
        longitude: Double,
        method: CalculationMethodId
    ) -> Date {
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: date)
        guard let times = PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: params(for: method)
        ) else {
            return date
        }
        return times.fajr
    }

    static func nextFajr(
        now: Date = Date(),
        latitude: Double,
        longitude: Double,
        method: CalculationMethodId
    ) -> (fajr: Date, dayAnchor: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let fajrToday = fajr(for: today, latitude: latitude, longitude: longitude, method: method)
        if now < fajrToday {
            return (fajrToday, today)
        }
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let fajrTomorrow = fajr(for: tomorrow, latitude: latitude, longitude: longitude, method: method)
        return (fajrTomorrow, tomorrow)
    }
}
