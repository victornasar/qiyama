import Foundation

enum LocationPresets {
    static let sanDiego = LocationPreset(
        id: "san-diego",
        label: "San Diego, CA",
        latitude: 32.7157,
        longitude: -117.1611,
        timeZone: "America/Los_Angeles"
    )

    /// Major North American cities for onboarding / profile pick lists.
    static let majorNorthAmerica: [LocationPreset] = [
        // United States
        LocationPreset(id: "new-york", label: "New York, NY", latitude: 40.7128, longitude: -74.0060, timeZone: "America/New_York"),
        LocationPreset(id: "los-angeles", label: "Los Angeles, CA", latitude: 34.0522, longitude: -118.2437, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "chicago", label: "Chicago, IL", latitude: 41.8781, longitude: -87.6298, timeZone: "America/Chicago"),
        LocationPreset(id: "houston", label: "Houston, TX", latitude: 29.7604, longitude: -95.3698, timeZone: "America/Chicago"),
        LocationPreset(id: "phoenix", label: "Phoenix, AZ", latitude: 33.4484, longitude: -112.0740, timeZone: "America/Phoenix"),
        LocationPreset(id: "philadelphia", label: "Philadelphia, PA", latitude: 39.9526, longitude: -75.1652, timeZone: "America/New_York"),
        LocationPreset(id: "san-antonio", label: "San Antonio, TX", latitude: 29.4241, longitude: -98.4936, timeZone: "America/Chicago"),
        LocationPreset(id: "san-diego", label: "San Diego, CA", latitude: 32.7157, longitude: -117.1611, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "dallas", label: "Dallas, TX", latitude: 32.7767, longitude: -96.7970, timeZone: "America/Chicago"),
        LocationPreset(id: "san-jose", label: "San Jose, CA", latitude: 37.3382, longitude: -121.8863, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "austin", label: "Austin, TX", latitude: 30.2672, longitude: -97.7431, timeZone: "America/Chicago"),
        LocationPreset(id: "jacksonville", label: "Jacksonville, FL", latitude: 30.3322, longitude: -81.6557, timeZone: "America/New_York"),
        LocationPreset(id: "fort-worth", label: "Fort Worth, TX", latitude: 32.7555, longitude: -97.3308, timeZone: "America/Chicago"),
        LocationPreset(id: "columbus", label: "Columbus, OH", latitude: 39.9612, longitude: -82.9988, timeZone: "America/New_York"),
        LocationPreset(id: "charlotte", label: "Charlotte, NC", latitude: 35.2271, longitude: -80.8431, timeZone: "America/New_York"),
        LocationPreset(id: "san-francisco", label: "San Francisco, CA", latitude: 37.7749, longitude: -122.4194, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "indianapolis", label: "Indianapolis, IN", latitude: 39.7684, longitude: -86.1581, timeZone: "America/Indiana/Indianapolis"),
        LocationPreset(id: "seattle", label: "Seattle, WA", latitude: 47.6062, longitude: -122.3321, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "denver", label: "Denver, CO", latitude: 39.7392, longitude: -104.9903, timeZone: "America/Denver"),
        LocationPreset(id: "washington-dc", label: "Washington, DC", latitude: 38.9072, longitude: -77.0369, timeZone: "America/New_York"),
        LocationPreset(id: "boston", label: "Boston, MA", latitude: 42.3601, longitude: -71.0589, timeZone: "America/New_York"),
        LocationPreset(id: "el-paso", label: "El Paso, TX", latitude: 31.7619, longitude: -106.4850, timeZone: "America/Denver"),
        LocationPreset(id: "nashville", label: "Nashville, TN", latitude: 36.1627, longitude: -86.7816, timeZone: "America/Chicago"),
        LocationPreset(id: "detroit", label: "Detroit, MI", latitude: 42.3314, longitude: -83.0458, timeZone: "America/Detroit"),
        LocationPreset(id: "oklahoma-city", label: "Oklahoma City, OK", latitude: 35.4676, longitude: -97.5164, timeZone: "America/Chicago"),
        LocationPreset(id: "portland", label: "Portland, OR", latitude: 45.5152, longitude: -122.6784, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "las-vegas", label: "Las Vegas, NV", latitude: 36.1699, longitude: -115.1398, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "memphis", label: "Memphis, TN", latitude: 35.1495, longitude: -90.0490, timeZone: "America/Chicago"),
        LocationPreset(id: "louisville", label: "Louisville, KY", latitude: 38.2527, longitude: -85.7585, timeZone: "America/Kentucky/Louisville"),
        LocationPreset(id: "baltimore", label: "Baltimore, MD", latitude: 39.2904, longitude: -76.6122, timeZone: "America/New_York"),
        LocationPreset(id: "milwaukee", label: "Milwaukee, WI", latitude: 43.0389, longitude: -87.9065, timeZone: "America/Chicago"),
        LocationPreset(id: "albuquerque", label: "Albuquerque, NM", latitude: 35.0844, longitude: -106.6504, timeZone: "America/Denver"),
        LocationPreset(id: "tucson", label: "Tucson, AZ", latitude: 32.2226, longitude: -110.9747, timeZone: "America/Phoenix"),
        LocationPreset(id: "fresno", label: "Fresno, CA", latitude: 36.7378, longitude: -119.7871, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "sacramento", label: "Sacramento, CA", latitude: 38.5816, longitude: -121.4944, timeZone: "America/Los_Angeles"),
        LocationPreset(id: "atlanta", label: "Atlanta, GA", latitude: 33.7490, longitude: -84.3880, timeZone: "America/New_York"),
        LocationPreset(id: "miami", label: "Miami, FL", latitude: 25.7617, longitude: -80.1918, timeZone: "America/New_York"),
        LocationPreset(id: "raleigh", label: "Raleigh, NC", latitude: 35.7796, longitude: -78.6382, timeZone: "America/New_York"),
        LocationPreset(id: "omaha", label: "Omaha, NE", latitude: 41.2565, longitude: -95.9345, timeZone: "America/Chicago"),
        LocationPreset(id: "minneapolis", label: "Minneapolis, MN", latitude: 44.9778, longitude: -93.2650, timeZone: "America/Chicago"),
        LocationPreset(id: "tampa", label: "Tampa, FL", latitude: 27.9506, longitude: -82.4572, timeZone: "America/New_York"),
        LocationPreset(id: "new-orleans", label: "New Orleans, LA", latitude: 29.9511, longitude: -90.0715, timeZone: "America/Chicago"),
        LocationPreset(id: "cleveland", label: "Cleveland, OH", latitude: 41.4993, longitude: -81.6944, timeZone: "America/New_York"),
        LocationPreset(id: "honolulu", label: "Honolulu, HI", latitude: 21.3069, longitude: -157.8583, timeZone: "Pacific/Honolulu"),
        LocationPreset(id: "orlando", label: "Orlando, FL", latitude: 28.5383, longitude: -81.3792, timeZone: "America/New_York"),
        LocationPreset(id: "st-louis", label: "St. Louis, MO", latitude: 38.6270, longitude: -90.1994, timeZone: "America/Chicago"),
        LocationPreset(id: "pittsburgh", label: "Pittsburgh, PA", latitude: 40.4406, longitude: -79.9959, timeZone: "America/New_York"),
        LocationPreset(id: "cincinnati", label: "Cincinnati, OH", latitude: 39.1031, longitude: -84.5120, timeZone: "America/New_York"),
        LocationPreset(id: "kansas-city", label: "Kansas City, MO", latitude: 39.0997, longitude: -94.5786, timeZone: "America/Chicago"),
        LocationPreset(id: "salt-lake-city", label: "Salt Lake City, UT", latitude: 40.7608, longitude: -111.8910, timeZone: "America/Denver"),
        LocationPreset(id: "richmond", label: "Richmond, VA", latitude: 37.5407, longitude: -77.4360, timeZone: "America/New_York"),
        LocationPreset(id: "buffalo", label: "Buffalo, NY", latitude: 42.8864, longitude: -78.8784, timeZone: "America/New_York"),
        // Canada
        LocationPreset(id: "toronto", label: "Toronto, ON", latitude: 43.6532, longitude: -79.3832, timeZone: "America/Toronto"),
        LocationPreset(id: "montreal", label: "Montreal, QC", latitude: 45.5017, longitude: -73.5673, timeZone: "America/Toronto"),
        LocationPreset(id: "vancouver", label: "Vancouver, BC", latitude: 49.2827, longitude: -123.1207, timeZone: "America/Vancouver"),
        LocationPreset(id: "calgary", label: "Calgary, AB", latitude: 51.0447, longitude: -114.0719, timeZone: "America/Edmonton"),
        LocationPreset(id: "edmonton", label: "Edmonton, AB", latitude: 53.5461, longitude: -113.4938, timeZone: "America/Edmonton"),
        LocationPreset(id: "ottawa", label: "Ottawa, ON", latitude: 45.4215, longitude: -75.6972, timeZone: "America/Toronto"),
        LocationPreset(id: "winnipeg", label: "Winnipeg, MB", latitude: 49.8951, longitude: -97.1384, timeZone: "America/Winnipeg"),
        LocationPreset(id: "quebec-city", label: "Quebec City, QC", latitude: 46.8139, longitude: -71.2080, timeZone: "America/Toronto"),
        LocationPreset(id: "hamilton", label: "Hamilton, ON", latitude: 43.2557, longitude: -79.8711, timeZone: "America/Toronto"),
        LocationPreset(id: "halifax", label: "Halifax, NS", latitude: 44.6488, longitude: -63.5752, timeZone: "America/Halifax"),
        // Mexico
        LocationPreset(id: "mexico-city", label: "Mexico City, MX", latitude: 19.4326, longitude: -99.1332, timeZone: "America/Mexico_City"),
        LocationPreset(id: "guadalajara", label: "Guadalajara, MX", latitude: 20.6597, longitude: -103.3496, timeZone: "America/Mexico_City"),
        LocationPreset(id: "monterrey", label: "Monterrey, MX", latitude: 25.6866, longitude: -100.3161, timeZone: "America/Monterrey"),
        LocationPreset(id: "tijuana", label: "Tijuana, MX", latitude: 32.5149, longitude: -117.0382, timeZone: "America/Tijuana"),
        LocationPreset(id: "cancun", label: "Cancún, MX", latitude: 21.1619, longitude: -86.8515, timeZone: "America/Cancun"),
    ]

    static let all = majorNorthAmerica

    static func filtered(query: String) -> [LocationPreset] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return majorNorthAmerica }
        return majorNorthAmerica.filter { $0.label.lowercased().contains(q) }
    }
}
