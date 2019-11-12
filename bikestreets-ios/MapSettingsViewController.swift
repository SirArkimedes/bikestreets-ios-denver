
import UIKit

class MapSettingsViewController: UITableViewController {
    
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Configure the NavBar
        title = NSLocalizedString("Map Settings", comment: "Title of view controller")
        let closeButton = UIBarButtonItem(barButtonSystemItem: .done,
                                          target: self,
                                          action: #selector(closeButtonAction(_:)))
        navigationItem.rightBarButtonItem = closeButton        
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Orient Map to:", comment: "")
        case 1:
            return NSLocalizedString("qwerty", comment: "")
        default:
            fatalError("Invalid section \(section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            fatalError("Invalid section \(section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: "asdf")
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("North", comment: "")
            } else {
                cell.textLabel?.text = NSLocalizedString("Direction of Travel", comment: "")
            }
        case 1:
            cell.textLabel?.text = NSLocalizedString("Keep screen on", comment: "")
        default:
            fatalError("Invalid section \(indexPath.section)")
        }
        return cell
    }
    

    
    
    // MARK: Button Action Methods
    
    @IBAction func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
