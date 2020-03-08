
import Foundation

class TermsManager {
    static let currentTermsText = NSLocalizedString("I will not sue Avi", comment: "")
    static let currentTermsVersion: Int = 1
    
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
