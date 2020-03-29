
import Foundation
import UIKit
import WebKit

// MARK: -
class TermsViewController: UIViewController, WKNavigationDelegate {
    // MARK: - IVARs
    @IBOutlet weak var termsWebView: WKWebView!
    @IBOutlet weak var waitingView: UIActivityIndicatorView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    let logger = Logger(name: "TermsViewController")
    
    // MARK: - View Controller overrides
    override func viewDidLoad() {
        guard let url = TermsManager.currentTermsURL else {
            fatalError("Unable to load URL for terms for Bike Streets.")
        }

        // Show the Terms in the webView
        waitingView.startAnimating()
        termsWebView.navigationDelegate = self
        if url.isFileURL {
            termsWebView.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            let request = URLRequest(url: TermsManager.currentTermsURL!)
            termsWebView.load(request)
        }
        
        declineButton.titleLabel?.text = NSLocalizedString("Decline", comment: "As in 'Decline' the terms of the app")
        acceptButton.titleLabel?.text = NSLocalizedString("Accept", comment: "As in 'Accept' the terms of the app")
        
        // Style the buttons
        declineButton.layer.cornerRadius = 5.0
        declineButton.layer.masksToBounds = true
        acceptButton.layer.cornerRadius = 5.0
        acceptButton.layer.masksToBounds = true
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        waitingView.stopAnimating()
    }
    
    // MARK: - Button Actions
    @IBAction func declineButtonAction(_ sender: Any) {
        // Log the declining of the Terms
        logger.log(eventName: "decline button tapped")
        
        // Quit the app gracefully so a crash is not logged.
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
    @IBAction func acceptButtonAction(_ sender: Any) {
        // Save that the Terms version that the user has accepted.
        TermsManager.acceptCurrentTerms()
        
        // Log the acceptance of the Terms
        logger.log(eventName: "accept button tapped")

        self.dismiss(animated: true, completion: nil)
    }
}
