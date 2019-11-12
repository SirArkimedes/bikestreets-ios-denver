
import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    // MARK: AppDelegate Overrides

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Keep the screen from locking
        application.isIdleTimerDisabled = true
        
        return true
    }
}

