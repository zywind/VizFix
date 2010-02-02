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
//			NSString *blipID = [eachTrial.ID substringFromIndex:5];
//			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID LIKE %@ *Classify", blipID];
//			
//			NSArray *blipsOfCurrentTrial = [blipsOfCurrentWave filteredArrayUsingPredicate:predicate];
			
			NSArray *subTrials = [[eachTrial.subTrials allObjects] 
								  sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
			for (VFSubTrial *subTrial in subTrials) {
				NSArray *fixations = [fixationsOfCurrentWave filteredArrayUsingPredicate:
									  [VFUtil predicateForObjectsWithStartTime:subTrial.startTime 
																	   endTime:subTrial.endTime]];
				
				NSMutableString *scanPath = [NSMutableString stringWithString:@""];
				for (VFFixation *eachFixation in fixations) {
					[scanPath appendFormat:@"%@,", eachFixation.fixatedAOI];
				}
				
				NSLog(@"%@", scanPath);
			}
		}
	}
}

@end
