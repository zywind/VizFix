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
	
	NSString *filePathBase = [[storeFileURL path] stringByDeletingPathExtension];
//	NSURL *outputFileURL = [NSURL fileURLWithPath:[filePathBase 
//												   stringByAppendingPathExtension:@"output"]];
	NSURL *scanPathFileURL = [NSURL fileURLWithPath:[filePathBase 
													 stringByAppendingPathExtension:@"scanpath"]];
	
	NSMutableString *scanPath = [NSMutableString stringWithString:@""];
	
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
			
			for (VFResponse *eachResponse in eachTrial.responses) {
				if ([eachResponse.measure isEqualToString:@"First Fixation On Radar RT"]
					|| [eachResponse.measure isEqualToString:@"First Fixation On Target RT"]
					|| [eachResponse.measure isEqualToString:@"Last Fixation To Tracking RT"]
					|| [eachResponse.measure isEqualToString:@"Inclassify Dwell Duration"]
					|| [eachResponse.measure isEqualToString:@"Preclassify Dwell Duration"])
					[managedObjectContext deleteObject:eachResponse];
			}
			
			NSArray *subTrials = [[eachTrial.subTrials allObjects] 
								  sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
			
			int timeOfFirstFixationOnRadar = -1;
			int timeOfFirstFixationOnTarget = -1;
			int timeOfLastFixationBackToTracking = -1;
			BOOL hasLookedAtRadar = NO;
			int inClassifyDuration = 0;
			int preClassifyDuration = 0;
			
			for (VFSubTrial *subTrial in subTrials) {	
				if ([subTrial.ID isEqualToString:@"PostClassify"])
					continue;
				
				NSArray *fixations = [fixationsOfCurrentWave filteredArrayUsingPredicate:
									  [VFUtil predicateForObjectsWithStartTime:subTrial.startTime 
																	   endTime:subTrial.endTime]];
				// Output scan path.
				NSString *lastFixatedAOI = nil;
				for (VFFixation *eachFixation in fixations) {
					if (![lastFixatedAOI isEqualToString:eachFixation.fixatedAOI]) {
						[scanPath appendFormat:@"%@,", eachFixation.fixatedAOI];
						lastFixatedAOI = eachFixation.fixatedAOI;
					}
					
					BOOL fixatedOnTarget = NO;
					NSArray *fixatedAOIs = [eachFixation.fixatedAOI componentsSeparatedByString:@"&"];
					for (NSString *eachFixatedAOI in fixatedAOIs) {
						if ([eachFixatedAOI isEqualToString:[NSString stringWithFormat:@"%@ %@", blipID, subTrial.ID]]) {
							fixatedOnTarget = YES;
							break;
						}
					}
					// Accumulate fixation duration on target blip.
					if (fixatedOnTarget) {
						if ([subTrial.ID isEqualToString:@"InClassify"])
							inClassifyDuration += [eachFixation.endTime intValue] - [eachFixation.startTime intValue];
						else
							preClassifyDuration += [eachFixation.endTime intValue] - [eachFixation.startTime intValue];
					}
					
					if ([subTrial.ID isEqualToString:@"InClassify"]) {
						// First time on the target
						if ((timeOfFirstFixationOnTarget == -1) && fixatedOnTarget) {
							hasLookedAtRadar = YES;
							timeOfFirstFixationOnTarget = 
							([subTrial.startTime intValue] <= [eachFixation.startTime intValue]) 
							? [eachFixation.startTime intValue] - [subTrial.startTime intValue] : 0;
							if (timeOfFirstFixationOnRadar == -1)
								timeOfFirstFixationOnRadar = timeOfFirstFixationOnTarget;
						} else if ((timeOfFirstFixationOnTarget == -1) // First time on the radar display
								   && (timeOfFirstFixationOnRadar == -1)
								   && ![eachFixation.fixatedAOI isEqualToString:@"Tracking Display"]
								   && ![eachFixation.fixatedAOI isEqualToString:@"Other"]) {
							hasLookedAtRadar = YES;
							timeOfFirstFixationOnRadar =
							([subTrial.startTime intValue] <= [eachFixation.startTime intValue]) 
							? [eachFixation.startTime intValue] - [subTrial.startTime intValue] : 0;
						} else if (hasLookedAtRadar && [eachFixation.fixatedAOI isEqualToString:@"Tracking Display"]) {
							timeOfLastFixationBackToTracking = [eachFixation.startTime intValue] - [subTrial.startTime intValue];
						}
					}
				}
				[scanPath deleteCharactersInRange:NSMakeRange([scanPath length] - 1, 1)];
				[scanPath appendString:@"\n"];
			}
			
			VFResponse *r1 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r1.measure = @"First Fixation On Radar RT";
			r1.value = [[NSNumber numberWithInt:timeOfFirstFixationOnRadar] stringValue];
			
			VFResponse *r2 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r2.measure = @"First Fixation On Target RT";
			r2.value = [[NSNumber numberWithInt:timeOfFirstFixationOnTarget] stringValue];
			
			VFResponse *r3 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r3.measure = @"Last Fixation To Tracking RT";
			r3.value = [[NSNumber numberWithInt:timeOfLastFixationBackToTracking] stringValue];
			
			VFResponse *r4 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r4.measure = @"Inclassify Dwell Duration";
			r4.value = [[NSNumber numberWithInt:inClassifyDuration] stringValue];
			
			VFResponse *r5 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r5.measure = @"Preclassify Dwell Duration";
			r5.value = [[NSNumber numberWithInt:preClassifyDuration] stringValue];
			
			[eachTrial addResponses:[NSSet setWithObjects:r1, r2, r3, r4, r5, nil]];
		}
	}
	
	NSError *error;
	BOOL ok = [scanPath writeToURL:scanPathFileURL
						atomically:NO 
						  encoding:NSUnicodeStringEncoding 
							 error:&error];
	if (!ok) {
		// an error occurred
		NSLog(@"Error writing file at %@\n%@", 
			  [scanPathFileURL path], 
			  [error localizedFailureReason]);
	}
	
	if (![managedObjectContext save:&error]) {
		NSLog(@"Save data failed at %@\n%@", [scanPathFileURL path], [error localizedFailureReason]);
	}
}

@end
