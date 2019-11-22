
import Foundation

/**
 * Generic wrapper for user settings that stores the values in UserDefaults and
 *
 * https://swiftsenpai.com/swift/create-the-perfect-userdefaults-wrapper-using-property-wrapper/
 */
@propertyWrapper
struct UserSettingStorage<T> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            // Read value from UserDefaults
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            // Set value to UserDefaults
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

/**
 * Simple class to store user settings such as map preferences, whether the user accepted ToS, etc.
 */
struct UserSettings {
    @UserSettingStorage(key: "mapviewtype_key", defaultValue: MapViewType.map.rawValue)
    static var mapViewType: String
    
    @UserSettingStorage(key: "maporientation_key", defaultValue: MapDirectionOfTravel.north.rawValue)
    static var mapOrientation: String
    
    @UserSettingStorage(key: "preventscreenlockonmap_key", defaultValue: false)
    static var preventScreenLockOnMap: Bool
}
