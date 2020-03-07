
import Foundation
import UIKit

// MARK: -
class TermsViewController: UIViewController {
    // MARK: - IVARs
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    // MARK: - View Controller overrides
    override func viewDidLoad() {
        declineButton.titleLabel?.text = NSLocalizedString("Decline", comment: "As in 'Decline' the terms of the app")
        acceptButton.titleLabel?.text = NSLocalizedString("Accept", comment: "As in 'Accept' the terms of the app")
    }
    
    // MARK: - Button Actions
    @IBAction func declineButtonAction(_ sender: Any) {
        // TODO: Log the declining of the Terms
        // TODO: Quit the app?
    }
    @IBAction func acceptButtonAction(_ sender: Any) {
        // TODO: Save the acceptance of the Terms
        // TODO: Log the acceptance of the Terms
        self.dismiss(animated: true, completion: nil)
    }
}
