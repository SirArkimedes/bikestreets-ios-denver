
import Foundation
import UIKit
import WebKit

// MARK: -
class TermsViewController: UIViewController {
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
        
        // Styling
        TermsViewController.configureStyleFor(button: declineButton)
        TermsViewController.configureStyleFor(button: acceptButton)
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
    
    // MARK: - Private Methods
    class func configureStyleFor(button: UIButton) {
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5.0
        button.layer.masksToBounds = true
    }
}

// MARK: - WKNavigationDelegate
extension TermsViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        waitingView.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // If the user taps a link, hand it over to the system to open (probably Safari)
        if navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url,
            UIApplication.shared.canOpenURL(url) {

            self.logger.log(eventName: "User tapped URL \(url). Opening URL in Safari")
            UIApplication.shared.open(url)

            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
