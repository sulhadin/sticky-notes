import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        container = NSPersistentCloudKitContainer(name: "StickyMarkdown")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store descriptions found")
        }

        // CloudKit configuration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.sulhadin.sticky-markdown"
        )

        // Enable remote change notifications
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable persistent history tracking (required for CloudKit sync)
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { description, error in
            if let error {
                print("Core Data store failed to load: \(error)")
            }
        }

        // Auto-merge remote changes into the view context
        viewContext.automaticallyMergesChangesFromParent = true

        // Last-write-wins per property
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save failed: \(error)")
        }
    }
}
