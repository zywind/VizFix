/********************************************************************
 File:   VFFetchHelper.m
 
 Created:  6/18/10
 Modified: 7/15/10
 
 Author: Yunfeng Zhang
 Cognitive Modeling and Eye Tracking Lab
 CIS Department
 University of Oregon
 
 Funded by the Office of Naval Research & National Science Foundation.
 Primary Investigator: Anthony Hornof.
 
 Copyright (c) 2010 by the University of Oregon.
 ALL RIGHTS RESERVED.
 
 Permission to use, copy, and distribute this software in
 its entirety for non-commercial purposes and without fee,
 is hereby granted, provided that the above copyright notice
 and this permission notice appear in all copies and their
 documentation.
 
 Software developers, consultants, or anyone else who wishes
 to use all or part of the software or its documentation for
 commercial purposes should contact the Technology Transfer
 Office at the University of Oregon to arrange a commercial
 license agreement.
 
 This software is provided "as is" without expressed or
 implied warranty of any kind.
 ********************************************************************/

#import "VFFetchHelper.h"
#import "VFUtil.h"
#import "VFSession.h"

@implementation VFFetchHelper

- (id)initWithMOC:(NSManagedObjectContext *)anMOC
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
		exit(1);
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
		exit(1);
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
        if ([entityName isEqualToString:@"Fixation"]) {
            fetchResults = [fetchResults filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category != %@", @"has error"]];
        }
        
		return fetchResults;
	} else {
		// TODO: refine error
		NSLog(@"Fetch %@ failed.\n%@", entityName, [fetchError localizedDescription]);
		exit(1);
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
