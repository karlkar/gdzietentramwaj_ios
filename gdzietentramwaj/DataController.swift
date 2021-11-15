import Foundation
import CoreData

class DataController {
    let persistenceContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistenceContainer.viewContext
    }
    
    init(modelName: String) {
        persistenceContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistenceContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
