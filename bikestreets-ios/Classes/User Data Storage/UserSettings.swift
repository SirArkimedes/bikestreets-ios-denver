
import Foundation

// MARK: -

/**
 * Simple class to store user settings such as map preferences, whether the user accepted ToS, etc.
 */
struct UserSettings {
    @UserSettingStorage(key: .lastTermsAccepted, defaultValue: 0)
    static var lastTermsAccepted: Int
    
    @UserSettingStorage(key: .mapZoomLevel, defaultValue: MapViewDefaults.zoomLevel)
    static var mapZoomLevel: Double
    
    @UserSettingStorage(key: .mapViewType, defaultValue: MapViewType.map.rawValue)
    static var mapViewTypeRaw: String
    static var mapViewType: MapViewType {
        get {
            return MapViewType(rawValue: mapViewTypeRaw)!
        }
        set {
            mapViewTypeRaw = newValue.rawValue
        }
    }
    
    @UserSettingStorage(key: .mapOrientation, defaultValue: MapOrientation.fixed.rawValue)
    static var mapOrientationRaw: String
    static var mapOrientation: MapOrientation {
        get {
            return MapOrientation(rawValue: mapOrientationRaw)!
        }
        set {
            mapOrientationRaw = newValue.rawValue
        }
    }
    
    @UserSettingStorage(key: .preventScreenLockOnMap, defaultValue: false)
    static var preventScreenLockOnMap: Bool
}

enum MapViewType: String {
    case map = "map"
    case satellite = "satellite"
}

enum MapOrientation: String {
    case fixed = "fixed"
    case directionOfTravel = "directionOfTravel"
}

// MARK: -
/**
 * Wrap the keys (strings) in a simple object
 */
struct Key: RawRepresentable {
    let rawValue: String
}

extension Key: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        rawValue = stringLiteral
    }
}

extension Key {
    static let lastTermsAccepted: Key = "lasttermsaccepted_key"
    static let mapZoomLevel: Key = "mapzoomlevel_key"
    static let mapViewType: Key = "mapviewtype_key"
    static let mapOrientation: Key = "maporientation_key"
    static let preventScreenLockOnMap: Key = "preventscreenlockonmap_key"
}

// MARK: -
/**
 * Use a protocol to safely limit the data types that can be stored in UserDefaults
 */
protocol PropertyListValue {}

extension Data: PropertyListValue {}
extension String: PropertyListValue {}
extension Date: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}

// Every element must be a property-list type
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}

// MARK: -
/**
 * Generic wrapper for user settings that stores the values in UserDefaults
 *
 * https://swiftsenpai.com/swift/create-the-perfect-userdefaults-wrapper-using-property-wrapper/
 * https://www.vadimbulavin.com/advanced-guide-to-userdefaults-in-swift/
 */
@propertyWrapper
struct UserSettingStorage<T: PropertyListValue> {
    private let key: Key
    private let defaultValue: T

    init(key: Key, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            // Read value from UserDefaults
            return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            // Set value to UserDefaults
            UserDefaults.standard.set(newValue, forKey: key.rawValue)
        }
    }
    
    var projectedValue: UserSettingStorage<T> { return self }
    func observe(change: @escaping (T?, T?) -> Void) -> NSObject {
        return UserDefaultsObserver(key: key) { old, new in
            change(old as? T, new as? T)
        }
    }
}

// MARK: -
/**
 * Class to wrap key/value observation of a specific UserDefaults entry (key)
 */
class UserDefaultsObserver: NSObject {
    let key: Key
    private var onChange: (Any, Any) -> Void

    init(key: Key, onChange: @escaping (Any, Any) -> Void) {
        self.onChange = onChange
        self.key = key
        super.init()
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: key.rawValue,
                                          options: [.old, .new],
                                          context: nil)
    }
    
    /**
     * You MUST hold onto the observer object that is returned, otherwise it gets removed
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change,
            object != nil,
            keyPath == key.rawValue else {
                return
        }
        
        onChange(change[.oldKey] as Any, change[.newKey] as Any)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key.rawValue, context: nil)
    }
}
