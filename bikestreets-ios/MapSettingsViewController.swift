
import UIKit

class MapSettingsViewController: UIViewController {
    
    // MARK: UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Map Settings", comment: "Title of view controller")
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .done,
                                          target: self,
                                          action: #selector(closeButtonAction(_:)))
        navigationItem.rightBarButtonItem = closeButton
        
    }
    
    // MARK: - Button Action Methods
    
    @IBAction func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
