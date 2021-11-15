import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let dataController = DataController(modelName: "VehicleModel")
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let mapViewController = navigationController.topViewController as! MapViewController
        mapViewController.dataController = dataController
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveViewContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveViewContext()
    }
    
    func saveViewContext() {
        try? dataController.viewContext.save()
    }
}

