#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#include <unistd.h>

#import "VFDualTaskImport.h"
#import "VFDualTaskAnalyzer.h"

void changeStore(NSPersistentStoreCoordinator *coordinator, NSURL *storeURL)
{
	// remove old store.
	NSError *error = nil;
	NSArray *oldStores = [coordinator persistentStores];
	if ([oldStores count] != 0) {
		[coordinator removePersistentStore:[oldStores objectAtIndex:0]
									 error:&error];
		if (error != nil) {
			NSLog(@"Cannot remove previous store.");
			exit(1);
		}
	}
	// add new store.
	NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
															configuration:nil
																	  URL:storeURL
																  options:nil
																	error:&error];
	if (newStore == nil) {
		NSLog(@"Store Configuration Failure\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
		return;
	}
	
}

int main (int argc, const char * argv[]) {
	objc_startCollectorThread();

	int ch;
	BOOL importMode = NO;
	
	// This piece of code is taken from here:
	// http://www.gnu.org/software/libtool/manual/libc/Example-of-Getopt.html#Example-of-Getopt
	while((ch = getopt(argc, argv, "a:i:")) != -1)
	{
		switch (ch) {
			case 'i':
				importMode = YES;
				break;
			case 'a':
				importMode = NO;
				break;
			case '?':
			default:
				NSLog(@"Unkown mode.");
				return 1;
		}
	}
	
	// load model
	NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] 
								 initWithContentsOfURL:[NSURL fileURLWithPath:@"VFModel.mom"]];
	NSPersistentStoreCoordinator *coordinator =
	[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
	
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator: coordinator];
	[moc setUndoManager:nil];
	
	VFDualTaskImport *importer = nil;
	VFDualTaskAnalyzer *analyzer = nil;
	
	if (importMode) {
		importer = [[VFDualTaskImport alloc] initWithMOC:moc];
	}
	else {
		analyzer = [[VFDualTaskAnalyzer alloc] init];
		analyzer.managedObjectContext = moc;
	}
	
	NSURL *argURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]]];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	BOOL isDir;
	
	if ([fileManager fileExistsAtPath:[argURL path] isDirectory:&isDir]) {
		if (isDir) {
			NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:[argURL path] error:NULL];
			for (NSString *eachPath in filePaths) {
				// import all text files.
				if (importMode && [[eachPath pathExtension] isEqualToString:@"txt"]) {
					NSString *storePath = [[eachPath stringByDeletingPathExtension] 
										   stringByAppendingString:@".vizfixsql"];
					if ([fileManager fileExistsAtPath:storePath]) {
						NSLog(@"The store file %@ already exists.", storePath);
						continue;
					}
					
					NSURL *storeURL = [NSURL fileURLWithPath:storePath];
					changeStore(coordinator, storeURL);
					
					[importer import:[NSURL fileURLWithPath:eachPath]];
				} else if (!importMode // Or analyze all vizfixsql files.
						   && [[eachPath pathExtension] isEqualToString:@"vizfixsql"]) {
					changeStore(coordinator, [NSURL fileURLWithPath:eachPath]);
					[analyzer analyze:[NSURL fileURLWithPath:eachPath]];
				}
			}
		} else {// Just one file to import.
			if (importMode) {
				changeStore(coordinator, argURL);
				[importer import:argURL];
			}
			else {
				changeStore(coordinator, argURL);
				[analyzer analyze:argURL];
			}
		}
	} else {
		NSLog(@"The file %@ does not exist.", [argURL path]);
	}
	
	return 0;
}