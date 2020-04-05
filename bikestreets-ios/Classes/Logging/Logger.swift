
import Foundation

class Logger {
    
    // MARK: - Shared Logger
    private static var sharedLogger: Logger = {
        let logger = Logger()

        // Configuration

        return logger
    }()

    class func shared() -> Logger {
        return sharedLogger
    }
    
    // MARK: - Init
    private convenience init() {
        self.init(name: "shared")
    }
    
    init(name: String) {
        self.name = name
    }

    // MARK: - Properties
    let name: String
    
    // MARK: - Methods for Logging Events
    func log(eventName: String) {
        #if DEBUG
        Swift.print("LOGGER \(name): \(eventName)")
        #endif
    }
}
