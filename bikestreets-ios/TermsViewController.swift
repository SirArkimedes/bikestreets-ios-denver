
import Foundation
import UIKit

// MARK: -
class TermsViewController: UIViewController {
    // MARK: - IVARs
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    // MARK: - View Controller overrides
    override func viewDidLoad() {
        termsTextView.text = TermsManager.currentTermsText
        declineButton.titleLabel?.text = NSLocalizedString("Decline", comment: "As in 'Decline' the terms of the app")
        acceptButton.titleLabel?.text = NSLocalizedString("Accept", comment: "As in 'Accept' the terms of the app")
        
        // Style the buttons
        declineButton.layer.cornerRadius = 5.0
        declineButton.layer.masksToBounds = true
        acceptButton.layer.cornerRadius = 5.0
        acceptButton.layer.masksToBounds = true
    }
    
    // MARK: - Button Actions
    @IBAction func declineButtonAction(_ sender: Any) {
        // TODO: Log the declining of the Terms

        // Quit the app gracefully so a crash is not logged.
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
    @IBAction func acceptButtonAction(_ sender: Any) {
        // Save that the Terms version that the user has accepted.
        TermsManager.acceptCurrentTerms()
        
        // TODO: Log the acceptance of the Terms

        self.dismiss(animated: true, completion: nil)
    }
}
