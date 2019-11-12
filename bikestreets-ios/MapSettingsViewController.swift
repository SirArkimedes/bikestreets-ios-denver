
import UIKit

enum MapSettingsSections: Int {
    case orientation = 0
    case other = 1
}

enum MapDirectionOfTravel: String {
    case north = "north"
    case directionOfTravel = "directionOfTravel"
}

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
        case MapSettingsSections.orientation.rawValue:
            return NSLocalizedString("Orient Map to:", comment: "")
        case MapSettingsSections.other.rawValue:
            return " "
        default:
            fatalError("Invalid section \(section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case MapSettingsSections.orientation.rawValue:
            return 2
        case MapSettingsSections.other.rawValue:
            return 1
        default:
            fatalError("Invalid section \(section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case MapSettingsSections.orientation.rawValue:
            let orientation = UserSettings.mapOrientation
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: "checkmark")
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("North", comment: "")
                cell.accessoryType = (orientation == MapDirectionOfTravel.north.rawValue) ? .checkmark : .none
            } else {
                cell.textLabel?.text = NSLocalizedString("Direction of Travel", comment: "")
                cell.accessoryType = (orientation == MapDirectionOfTravel.directionOfTravel.rawValue) ? .checkmark : .none
            }

            return cell
            
        case MapSettingsSections.other.rawValue:
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = UserSettings.preventScreenLockOnMap
            toggleSwitch.addTarget(self, action: #selector(toggleScreenLockSwitch(_:)), for: .valueChanged)
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: "switch")
            cell.selectionStyle = .none
            cell.textLabel?.text = NSLocalizedString("Keep screen on", comment: "")
            cell.accessoryView = toggleSwitch
            
            return cell
        
        default:
            fatalError("Invalid section \(indexPath.section)")
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case MapSettingsSections.orientation.rawValue:
            // Save the change
            if indexPath.row == 0 {
                UserSettings.mapOrientation = MapDirectionOfTravel.north.rawValue
            } else {
                UserSettings.mapOrientation = MapDirectionOfTravel.directionOfTravel.rawValue
            }

            // Update the UI
            checkOnlyCellAt(indexPath: indexPath, in: tableView)
            
        case MapSettingsSections.other.rawValue:
            return
        default:
            fatalError("Invalid section \(indexPath.section)")
        }
    }
    
    func checkOnlyCellAt(indexPath: IndexPath, in tableView: UITableView) {
        // Uncheck the other cells in the section
        let numberOfCells = tableView.numberOfRows(inSection: indexPath.section)
        for i in 0..<numberOfCells {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: indexPath.section)) {
                cell.accessoryType = .none
            }
        }
        
        // Check the current cell
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
    }
    
    // MARK: Button Action Methods
    
    @IBAction func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func toggleScreenLockSwitch(_ sender: Any) {
        guard let toggleSwitch = sender as? UISwitch else {
            fatalError("toggleScreenLockSwitch should only accept a UISwitch")
        }
        
        UserSettings.preventScreenLockOnMap = toggleSwitch.isOn
    }
}
