#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VFDualTaskImport.h"

NSManagedObjectContext *managedObjectContext(NSURL *storeURL);

int main (int argc, const char * argv[]) {
	objc_startCollectorThread();

	// load model
	NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] 
								 initWithContentsOfURL:[NSURL fileURLWithPath:@"VFModel.mom"]];
	NSPersistentStoreCoordinator *coordinator =
	[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
	
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator: coordinator];
	[moc setUndoManager:nil];
	
	VFDualTaskImport *importer = [[VFDualTaskImport alloc] initWithMOC:moc];
	
	NSURL *importURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	BOOL isDir;
	
	if ([fileManager fileExistsAtPath:[importURL path] isDirectory:&isDir]) {
		if (isDir) {
			NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:[importURL path] error:NULL];
			for (NSString *eachPath in filePaths) {
				// import all text files.
				if ([[eachPath pathExtension] isEqualToString:@"txt"]) {
					NSURL *aURL = [NSURL fileURLWithPath:eachPath];
					[importer import:aURL];
				}
			}
		} else {// Just one file to import.
			[importer import:importURL];
		}
	} else {
		NSLog(@"The file %@ does not exist.", [importURL path]);
	}
	
	return 0;
}