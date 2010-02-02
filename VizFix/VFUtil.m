//
//  VFUtil.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/30/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFUtil.h"


@implementation VFUtil

static NSArray *startTimeSort = nil;
static NSArray *timeSort = nil;
static NSArray *visualStimuliSort = nil;
#pragma mark -
#pragma mark ---------SORT DESCRIPTORS---------

+ (NSArray *)startTimeSortDescriptor
{
	if (startTimeSort == nil) 
		startTimeSort = [NSArray arrayWithObject:[[NSSortDescriptor alloc] 
												  initWithKey:@"startTime" ascending:YES]];
	return startTimeSort;
}

+ (NSArray *)timeSortDescriptor
{
	if (timeSort == nil)
		timeSort = [NSArray arrayWithObject:[[NSSortDescriptor alloc] 
											 initWithKey:@"time" ascending:YES]];
	return timeSort;
}

+ (NSArray*)visualStimuliSortDescriptors
{
	if (visualStimuliSort == nil) {
		NSSortDescriptor *zorderSort = [[NSSortDescriptor alloc] initWithKey:@"template.zorder" ascending:YES];
		NSSortDescriptor *timeSort = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
		visualStimuliSort = [NSArray arrayWithObjects:zorderSort, timeSort, nil];
	}
	return visualStimuliSort;
}

+ (NSArray *)fetchModelObjectsForName:(NSString *)entityName 
								 from:(NSNumber *)startTime 
								   to:(NSNumber *)endTime 
							  withMOC:(NSManagedObjectContext *)moc
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

+ (VFSession *)fetchSessionWithMOC:(NSManagedObjectContext *)moc
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

+ (NSArray *)fetchAllObjectsForName:(NSString *)entityName fromMOC:(NSManagedObjectContext *)moc
{
	VFSession *session = [VFUtil fetchSessionWithMOC:moc];
	
	return [VFUtil fetchModelObjectsForName:entityName
									   from:[NSNumber numberWithInt:0] 
										 to:session.duration 
									withMOC:moc];
}

+ (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point
{
	return sqrt(pow(point.x - center.x, 2.0) + pow(point.y - center.y, 2.0));
}

+ (NSPredicate *)predicateForObjectsWithStartTime:(NSNumber *)startTime endTime:(NSNumber *)endTime
{
	return [NSPredicate predicateWithFormat:
			 @"(startTime <= %@ AND endTime >= %@) OR (startTime >= %@ AND startTime <= %@)", 
			 startTime, startTime, startTime, endTime];
}

+ (NSBezierPath *)autoAOIAroundCenter:(NSPoint)center withSize:(NSSize)aoiSize
{
	NSRect aoiRect = NSMakeRect(center.x - aoiSize.width/2, center.y - aoiSize.height/2, 
								aoiSize.width, aoiSize.height);
	
	return [NSBezierPath bezierPathWithOvalInRect:aoiRect];
}

+ (void)registerFixationsToAOIs:(NSDictionary *)customAOIs inMOC:(NSManagedObjectContext *)moc withAutoAOIDOV:(double)DOV
{
	NSArray *fixationArray = [VFUtil fetchAllObjectsForName:@"Fixation" fromMOC:moc];
	NSArray *visualStimuliArray = [VFUtil fetchAllObjectsForName:@"VisualStimulus" fromMOC:moc];
	
	VFVisualAngleConverter *converter = [[VFVisualAngleConverter alloc] initWithMOC:moc];
	
	for (VFFixation *eachFixation in fixationArray) {
		NSArray *onScreenStimuli = [visualStimuliArray filteredArrayUsingPredicate:
									[VFUtil predicateForObjectsWithStartTime:eachFixation.startTime endTime:eachFixation.endTime]];
		for (VFVisualStimulus *eachStimulus in onScreenStimuli) {
			NSSet *onScreenFrames = [eachStimulus.frames filteredSetUsingPredicate:
									   [VFUtil predicateForObjectsWithStartTime:eachFixation.startTime endTime:eachFixation.endTime]];
			
			for (VFVisualStimulusFrame *eachFrame in onScreenFrames) {
				NSPoint center = NSMakePoint(eachFrame.location.x + eachStimulus.template.center.x, 
											 eachFrame.location.y + eachStimulus.template.center.y);
				
				NSSize autoAOISize = NSMakeSize([converter horizontalPixelsFromVisualAngles:DOV], 
												[converter verticalPixelsFromVisualAngles:DOV]);
				NSBezierPath *aoiPath = [VFUtil autoAOIAroundCenter:center withSize:autoAOISize];
				if ([aoiPath containsPoint:eachFixation.location]) {
					[eachFixation registerOnAOI:eachStimulus.ID];
					break;
				}
			}
		}
		
		// If the fixation is not fixated on any on screen stimulus, then see if it is on custom AOIs.
		if (eachFixation.fixatedAOI == nil) {
			for (id key in customAOIs) {
				NSBezierPath *aoiPath = [customAOIs objectForKey:key];
				if ([aoiPath containsPoint:eachFixation.location]) {
					[eachFixation registerOnAOI:key];
				}
			}
			// If it's still nil, it's on "Other" area.
			if (eachFixation.fixatedAOI == nil) {
				[eachFixation registerOnAOI:@"Other"];
			}
		}
	}
}

@end
