#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VFDualTaskImport.h"

NSManagedObjectContext *managedObjectContext(NSURL *storeURL);

int main (int argc, const char * argv[]) {
	objc_startCollectorThread();

	
    NSURL *storeURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]]];
	NSManagedObjectContext *moc = managedObjectContext(storeURL);

	VFDualTaskImport *importer = [[VFDualTaskImport alloc] initWithMOC:moc];
	[importer import:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
	
    return 0;
}

NSManagedObjectContext *managedObjectContext(NSURL *storeURL)
{
    static NSManagedObjectContext *moc = nil;
    if (moc != nil) {
        return moc;
    }
	
    moc = [[NSManagedObjectContext alloc] init];
	// load model
	NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@"VFModel.mom"]];
	
	NSPersistentStoreCoordinator *coordinator =
		[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    [moc setPersistentStoreCoordinator: coordinator];
	
    NSString *STORE_TYPE = NSSQLiteStoreType;
	
    NSError *error;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	if ([fileManager fileExistsAtPath:[storeURL path]]) {
		if (![fileManager removeItemAtPath:[storeURL path] error:&error]) {
			NSLog(@"Cannot remove the previous store.\n%@",
				  ([error localizedDescription] != nil) ?
				  [error localizedDescription] : @"Unknown Error");
		}
	}
	
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:STORE_TYPE
															configuration:nil
																	  URL:storeURL
																  options:nil
																	error:&error];
	
    if (newStore == nil) {
        NSLog(@"Store Configuration Failure\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
    }
	
    return moc;
}