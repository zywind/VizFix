//
//  VFDualTaskAnalyzer.m
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 1/31/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFDualTaskAnalyzer.h"

@implementation VFDualTaskAnalyzer
@synthesize managedObjectContext;

- (id)init
{	
	if (self = [super init]) {
		radarAOI = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 180, 710, 512)];
		trackingAOI = [NSBezierPath bezierPathWithRect:NSMakeRect(740, 242, 540, 540)];
    }
    return self;
}

- (void)analyze:(NSURL *)storeFileURL
{
	VFSession *session = [VFUtil fetchSessionWithMOC:managedObjectContext];
	NSArray *blocks = [[session.blocks allObjects] 
					   sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
	for (VFBlock *eachBlock in blocks) {
		blipsOfCurrentWave = [VFUtil fetchModelObjectsForName:@"VisualStimulus" 
														 from:eachBlock.startTime 
														   to:eachBlock.endTime 
													  withMOC:managedObjectContext];
		NSArray *fixationsOfCurrentWave = [VFUtil fetchModelObjectsForName:@"Fixation" 
																	  from:eachBlock.startTime 
																		to:eachBlock.endTime 
																   withMOC:managedObjectContext];
		
		NSArray *trials = [[eachBlock.trials allObjects] 
						   sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
		for (VFTrial *eachTrial in trials) {
			NSString *blipID = [eachTrial.ID substringFromIndex:5];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID LIKE %@", blipID];
			
			NSArray *blipsOfCurrentTrial = [blipsOfCurrentWave filteredArrayUsingPredicate:predicate];
			
			NSArray *subTrials = [[eachTrial.subTrials allObjects] 
								  sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
			for (VFSubTrial *subTrial in subTrials) {
				predicate = [NSPredicate predicateWithFormat:@"startTime >= %@ AND endTime <= %@", 
							 subTrial.startTime, subTrial.endTime];
				targetBlip = [[blipsOfCurrentTrial filteredArrayUsingPredicate:predicate] 
							  objectAtIndex:0];
				
				predicate = [NSPredicate predicateWithFormat:
							 @"(startTime <= %@ AND endTime >= %@) OR \
							 (startTime >= %@ AND startTime <= %@)", 
							 subTrial.startTime, subTrial.startTime, 
							 subTrial.startTime, subTrial.endTime];
				
				NSArray *fixations = [fixationsOfCurrentWave filteredArrayUsingPredicate:predicate];
				
				for (VFFixation *eachFixation in fixations) {
					[self findFixatedAOIForFixations:eachFixation];
					// TODO scan path.
				}
			}
		}
	}
}

- (NSString *)findFixatedAOIForFixations:(VFFixation *)fixation
{
	if ([trackingAOI containsPoint:fixation.location]) {
		return @"T";
	} else if ([radarAOI containsPoint:fixation.location]) {
		return @"R";
	} else {
		return @"O";
	}
}

@end
