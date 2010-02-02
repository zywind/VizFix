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

@end
