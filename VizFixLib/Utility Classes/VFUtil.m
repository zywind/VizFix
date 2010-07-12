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

+ (NSBezierPath *)autoAOIAroundPoint:(NSPoint)point withSize:(NSSize)aoiSize
{
	NSRect aoiRect = NSMakeRect(point.x - aoiSize.width/2, point.y - aoiSize.height/2, 
								aoiSize.width, aoiSize.height);
	
	return [NSBezierPath bezierPathWithOvalInRect:aoiRect];
}

+ (id)managedObjectModel
{
	static id sharedModel = nil;
    if (sharedModel == nil) {
		NSString *modelPath = @"~/Library/Frameworks/VizFixLib.framework/Resources/VFModel.mom";
		NSURL *modelURL = [NSURL fileURLWithPath:[modelPath stringByExpandingTildeInPath]];
        sharedModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] retain];
    }
    return sharedModel;
}

@end
