
import Foundation

class TermsManager {
    static let currentTermsVersion: Int = 1
    static var currentTermsURL: URL? {
        get {
            return Bundle.main.url(forResource: "bike streets terms v1.0", withExtension: "webarchive")
//            return URL(string: "https://www.bikestreets.com/terms")
        }
    }
    
    static func hasAcceptedCurrentTerms() -> Bool {
        if UserSettings.lastTermsAccepted == TermsManager.currentTermsVersion {
            return true
        }
        return false
    }
    
    static func acceptCurrentTerms() {
        UserSettings.lastTermsAccepted = TermsManager.currentTermsVersion
    }
}
