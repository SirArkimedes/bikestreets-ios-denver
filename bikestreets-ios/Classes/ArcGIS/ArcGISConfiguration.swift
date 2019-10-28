
import Foundation

struct ArcGISConfiguration {
    static let clientID: String = "owehr3TUwlJEiNVY"
    
    static let urlScheme: String = "bikestreets"
    static let urlAuthPath: String = "bikestreets.com/oauth"
    
    static let keychainIdentifier: String = "\(Bundle.main.bundleIdentifier!).keychainIdentifier"
    static let oauthURL: URL = URL(string: "https://www.arcgis.com/sharing/rest/oauth2/token/")!
}
