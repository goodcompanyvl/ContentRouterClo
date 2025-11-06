import Foundation

public extension Bundle {
    var releaseDate: DateComponents {
        let year = object(forInfoDictionaryKey: "ReleaseYear") as? Int ?? 2025
        let month = object(forInfoDictionaryKey: "ReleaseMonth") as? Int ?? 1
        let day = object(forInfoDictionaryKey: "ReleaseDay") as? Int ?? 1
        return DateComponents(year: year, month: month, day: day)
    }
}

