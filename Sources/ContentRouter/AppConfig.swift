import Foundation

public enum ContentType: Equatable {
    case classic
    case withoutLibAndTest
    case dropbox
    case privacy(appleId: String)
}

public enum AppConfig {
    public static let contentSourceKey = "savedContentSource"
    public static let displayModeKey = "primaryMode"
    public static let accessCountKey = "enhancedSecurityAccessCount"
    public static let securityEngineBrowserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1"
    public static let classicPathIdKey = "classic_path_id"
    public static let privacyPathIdKey = "privacy_path_id"
    public static let privacyValidatedOnceKey = "privacy_validated_once"
    public static let dropboxFailedKey = "dropbox_failed_once"
    public static let dropboxSavedURLKey = "dropbox_saved_url"
    public static let networkTimeoutInterval: TimeInterval = 25.0
}
