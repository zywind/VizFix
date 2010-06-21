//
//  VFFetchHelper.m
//  VizFix
//
//  Created by Yunfeng Zhang on 6/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFFetchHelper.h"
#import "VFUtil.h"
#import "VFMangedObjects.h"


@implementation VFFetchHelper

- (id)initWithMoc:(NSManagedObjectContext *)anMOC
{	
	if (self = [super init]) {
		moc = anMOC;
	}
    return self;
}

- (VFSession *)session
{
	NSError *fetchError = nil;
	NSArray *fetchResults;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session"
											  inManagedObjectContext:moc];
	[fetchRequest setEntity:entity];
	
	fetchResults = [moc executeFetchRequest:fetchRequest error:&fetchError];
	if ((fetchResults != nil) && ([fetchResults count] == 1) && (fetchError == nil)) {
		return [fetchResults objectAtIndex:0];
	} else {
		NSLog(@"Fetch session failed!\n%@", [fetchError localizedDescription]);
		return nil;
	}
}

- (NSArray *)topLevelProcedures
{
	NSError *fetchError = nil;
	NSArray *fetchResults;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Procedure"
											  inManagedObjectContext:moc];
	[fetchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentProc == nil"];
	[fetchRequest setPredicate:predicate];

	[fetchRequest setSortDescriptors:[VFUtil startTimeSortDescriptor]];

	fetchResults = [moc executeFetchRequest:fetchRequest error:&fetchError];
	
	if ((fetchResults != nil) && (fetchError == nil)) {
		return fetchResults;
	} else {
		// TODO: refine error
		NSLog(@"Fetch top level procedures failed.\n%@", [fetchError localizedDescription]);
		return nil;
	}
}

- (NSArray *)fetchModelObjectsForName:(NSString *)entityName 
								 from:(NSNumber *)startTime 
								   to:(NSNumber *)endTime 
{
	NSError *fetchError = nil;
	NSPredicate * predicate;
	NSArray *fetchResults;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
											  inManagedObjectContext:moc];
	if ([entityName isEqualToString:@"GazeSample"] || [entityName isEqualToString:@"CustomEvent"]
		|| [entityName isEqualToString:@"KeyboardEvent"]) {
		predicate = [NSPredicate predicateWithFormat:
					 @"(time <= %@ AND time >= %@)", endTime, startTime];
		[fetchRequest setSortDescriptors:[VFUtil timeSortDescriptor]];
	} else {// TODO: constrian the entityName to only a few.
		predicate = [VFUtil predicateForObjectsWithStartTime:startTime endTime:endTime];
		
		// sort visual stimulus array based on zorder before return;
		if ([entityName isEqualToString:@"VisualStimulus"])
			[fetchRequest setSortDescriptors:[VFUtil visualStimuliSortDescriptors]];
		else
			[fetchRequest setSortDescriptors:[VFUtil startTimeSortDescriptor]];
	}
	
	[fetchRequest setEntity:entity];	
	[fetchRequest setPredicate:predicate];
	
	fetchResults = [moc executeFetchRequest:fetchRequest error:&fetchError];
	if ((fetchResults != nil) && (fetchError == nil)) {
		return fetchResults;
	} else {
		// TODO: refine error
		NSLog(@"Fetch %@ failed.\n%@", entityName, [fetchError localizedDescription]);
		return nil;
	}
}


- (NSArray *)fetchAllObjectsForName:(NSString *)entityName
{
	VFSession *session = [self session];
	
	return [self fetchModelObjectsForName:entityName
									 from:[NSNumber numberWithInt:0] 
									   to:session.duration];
}

@end
