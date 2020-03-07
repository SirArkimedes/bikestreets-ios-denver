
import Foundation

class TermsManager {
    static let currentTermsText = NSLocalizedString("I will not sue Avi", comment: "")
    static let currentTermsVersion: Int = 1
    
    static func hasUserAcceptedCurrentTerms() -> Bool {
        if UserSettings.lastTermsAccepted == TermsManager.currentTermsVersion {
            return true
        }
        return false
    }
}
