
import UIKit

enum MapSettingsSection: Int, CaseIterable {
    case viewType
    case orientation
    case other
}

enum MapViewType: String {
    case map = "map"
    case satellite = "satellite"
}

enum MapDirectionOfTravel: String {
    case fixed = "fixed"
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
        return MapSettingsSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let settingsSection = MapSettingsSection(rawValue: section) else {
            fatalError("Invalid section \(section)")
        }
        switch settingsSection {
        case .viewType:
            return NSLocalizedString("View:", comment: "")
        case .orientation:
            return NSLocalizedString("Orient Map to:", comment: "")
        case .other:
            return " "
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = MapSettingsSection(rawValue: section) else {
            fatalError("Invalid section \(section)")
        }
        switch settingsSection {
        case .viewType:
            return 2
        case .orientation:
            return 2
        case .other:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let settingsSection = MapSettingsSection(rawValue: indexPath.section) else {
            fatalError("Invalid section \(indexPath.section)")
        }
        switch settingsSection {
        case .viewType:
            let mapViewType = UserSettings.mapViewType
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: "checkmark")
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Map", comment: "")
                cell.accessoryType = (mapViewType == MapViewType.map.rawValue) ? .checkmark : .none
            } else {
                cell.textLabel?.text = NSLocalizedString("Satellite", comment: "")
                cell.accessoryType = (mapViewType == MapViewType.satellite.rawValue) ? .checkmark : .none
            }

            return cell

        case .orientation:
            let orientation = UserSettings.mapOrientation
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: "checkmark")
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Fixed", comment: "")
                cell.accessoryType = (orientation == MapDirectionOfTravel.fixed.rawValue) ? .checkmark : .none
            } else {
                cell.textLabel?.text = NSLocalizedString("Direction of Travel", comment: "")
                cell.accessoryType = (orientation == MapDirectionOfTravel.directionOfTravel.rawValue) ? .checkmark : .none
            }

            return cell
            
        case .other:
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = UserSettings.preventScreenLockOnMap
            toggleSwitch.addTarget(self, action: #selector(toggleScreenLockSwitch(_:)), for: .valueChanged)
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: "switch")
            cell.selectionStyle = .none
            cell.textLabel?.text = NSLocalizedString("Keep screen on", comment: "")
            cell.accessoryView = toggleSwitch
            
            return cell
        
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let settingsSection = MapSettingsSection(rawValue: indexPath.section) else {
            fatalError("Invalid section \(indexPath.section)")
        }
        switch settingsSection {
        case .viewType:
            // Save the change
            if indexPath.row == 0 {
                UserSettings.mapViewType = MapViewType.map.rawValue
            } else {
                UserSettings.mapViewType = MapViewType.satellite.rawValue
            }

            // Update the UI
            checkOnlyCellAt(indexPath: indexPath, in: tableView)
            
        case .orientation:
            // Save the change
            if indexPath.row == 0 {
                UserSettings.mapOrientation = MapDirectionOfTravel.fixed.rawValue
            } else {
                UserSettings.mapOrientation = MapDirectionOfTravel.directionOfTravel.rawValue
            }

            // Update the UI
            checkOnlyCellAt(indexPath: indexPath, in: tableView)
            
        case .other:
            return
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
