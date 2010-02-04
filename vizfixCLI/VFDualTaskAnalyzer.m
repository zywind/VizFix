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
		decimalFormatter = [[NSNumberFormatter alloc] init];
		[decimalFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[decimalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[decimalFormatter setMaximumFractionDigits:2];
    }
    return self;
}

- (void)analyze:(NSURL *)storeFileURL
{
	NSLog(@"Start to process file %@.", [storeFileURL path]);
	NSLog(@"Start to register fixations to AOIs.");
	// Register fixations to AOIs.
	NSBezierPath *radarAOI = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 180, 710, 512)];
	NSBezierPath *trackingAOI = [NSBezierPath bezierPathWithRect:NSMakeRect(740, 242, 540, 540)];
	NSDictionary *customAOIs = [NSDictionary dictionaryWithObjectsAndKeys:radarAOI, @"Radar Display", 
								trackingAOI, @"Tracking Display", nil];
	[VFUtil registerFixationsToAOIs:customAOIs inMOC:managedObjectContext withAutoAOIDOV:2.5];
	NSError *error;
	if (![managedObjectContext save:&error]) {
		NSLog(@"Register fixations failed at %@\n%@", [storeFileURL path], [error localizedFailureReason]);
		return;
	}
	NSLog(@"Registering fixations completed.");
	
	VFSession *session = [VFUtil fetchSessionWithMOC:managedObjectContext];
	NSArray *blocks = [[session.blocks allObjects]
					   sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
		
	for (VFBlock *eachBlock in blocks) {
		if ([eachBlock.ID isEqualToString:@"pause"]) {
			continue;
		}
		
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
			int firstKeyRT = 0;
			
			for (VFResponse *eachResponse in eachTrial.responses) {
				if ([eachResponse.measure isEqualToString:@"First Fixation On Radar RT"]
					|| [eachResponse.measure isEqualToString:@"First Fixation On Target RT"]
					|| [eachResponse.measure isEqualToString:@"Eyes On Tracking to Keypress"]
					|| [eachResponse.measure isEqualToString:@"Inclassify Dwell Duration"]
					|| [eachResponse.measure isEqualToString:@"Preclassify Dwell Duration"]
					|| [eachResponse.measure isEqualToString:@"Inclassify Scan Path"]
					|| [eachResponse.measure isEqualToString:@"Tracking Error Change"]) {
					[managedObjectContext deleteObject:eachResponse];
				} else if ([eachResponse.measure isEqualToString:@"First key RT"]) {
					firstKeyRT = [eachResponse.value intValue];
				}
			}
			
			NSArray *subTrials = [[eachTrial.subTrials allObjects] 
								  sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
			int dwellDuration[] = {0, 0};
			
			int timeOfFirstFixationOnRadar = -1;
			int timeOfFirstFixationOnTarget = -1;
			int timeOfLastFixationBackToTracking = -1;
			BOOL previousOnTracking = NO;
			NSMutableString *scanpath = [NSMutableString stringWithString:@""];
			NSString *lastFixatedAOI = nil;
	
			for (int i = 0; i < 2; i++) {
				VFSubTrial *subTrial = [subTrials objectAtIndex:i];
				
				NSArray *fixations = [fixationsOfCurrentWave filteredArrayUsingPredicate:
									  [VFUtil predicateForObjectsWithStartTime:subTrial.startTime 
																	   endTime:subTrial.endTime]];
				
				for (VFFixation *eachFixation in fixations) {
					BOOL fixatedOnTarget = NO;
					NSArray *fixatedAOIs = [eachFixation.fixatedAOI componentsSeparatedByString:@"&"];
					for (NSString *eachFixatedAOI in fixatedAOIs) {
						if ([eachFixatedAOI isEqualToString:[NSString stringWithFormat:@"%@ %@", blipID, subTrial.ID]]) {
							fixatedOnTarget = YES;
							// Accumulate fixation duration on target blip.
							dwellDuration[i] += [eachFixation.endTime intValue] - [eachFixation.startTime intValue];
							break;
						}
					}
					
					if (i == 1) {
						// Record scan path.
						if (![lastFixatedAOI isEqualToString:eachFixation.fixatedAOI]) {
							[scanpath appendFormat:@"%@, ", eachFixation.fixatedAOI];
							lastFixatedAOI = eachFixation.fixatedAOI;
						}
						// First time on the target
						if ((timeOfFirstFixationOnTarget == -1) && fixatedOnTarget) {
							timeOfFirstFixationOnTarget = 
							([subTrial.startTime intValue] <= [eachFixation.startTime intValue]) 
							? [eachFixation.startTime intValue] - [subTrial.startTime intValue] : 0;
							if (timeOfFirstFixationOnRadar == -1)
								timeOfFirstFixationOnRadar = timeOfFirstFixationOnTarget;
						} else if ((timeOfFirstFixationOnTarget == -1) // First time on the radar display
								   && (timeOfFirstFixationOnRadar == -1)
								   && ![eachFixation.fixatedAOI isEqualToString:@"Tracking Display"]
								   && ![eachFixation.fixatedAOI isEqualToString:@"Other"]) {
							timeOfFirstFixationOnRadar =
							([subTrial.startTime intValue] <= [eachFixation.startTime intValue]) 
							? [eachFixation.startTime intValue] - [subTrial.startTime intValue] : 0;
						} else if ([eachFixation.fixatedAOI isEqualToString:@"Tracking Display"]) {
							if (!previousOnTracking) {
								timeOfLastFixationBackToTracking = [eachFixation.startTime intValue];
							}
							previousOnTracking = YES;
						}
						
						if (![eachFixation.fixatedAOI isEqualToString:@"Tracking Display"])
							previousOnTracking = NO;
					}
				}
			}
			if([scanpath length] != 0)
				[scanpath deleteCharactersInRange:NSMakeRange([scanpath length] - 2, 2)];
			
			VFResponse *r1 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r1.measure = @"First Fixation On Radar RT";
			if (timeOfFirstFixationOnRadar != -1) {
				r1.value = [[NSNumber numberWithInt:timeOfFirstFixationOnRadar] stringValue];
			} else {
				r1.value = @"NA";
			}
			
			VFResponse *r2 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r2.measure = @"First Fixation On Target RT";
			if (timeOfFirstFixationOnTarget != -1) {
				r2.value = [[NSNumber numberWithInt:timeOfFirstFixationOnTarget] stringValue];
			} else {
				r2.value = @"NA";
			}
			
			VFResponse *r3 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r3.measure = @"Eyes On Tracking to Keypress";
			VFResponse *te = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			te.measure = @"Tracking Error Change";
			if (firstKeyRT != 0 && timeOfLastFixationBackToTracking != -1) {
				VFSubTrial *inclassifySubTrial = [subTrials objectAtIndex:1];
				r3.value = [[NSNumber numberWithInt:firstKeyRT - 
							 (timeOfLastFixationBackToTracking - [inclassifySubTrial.startTime intValue])] stringValue];
				
				if ([r3.value intValue] > 0) {
					// Get the tracking error relative change.
					NSArray *trackingErrorsOfInclassifySubTrial = [VFUtil fetchModelObjectsForName:@"CustomEvent" 
																							  from:[NSNumber numberWithInt:timeOfLastFixationBackToTracking]
																								to:[NSNumber numberWithInt:[inclassifySubTrial.endTime intValue] - 100]
																						   withMOC:managedObjectContext];
					
					NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"category LIKE 'tracking error'"];
					trackingErrorsOfInclassifySubTrial = [trackingErrorsOfInclassifySubTrial
														  filteredArrayUsingPredicate:filterPredicate];
					
					double teWhenKeyIn = [((VFCustomEvent *)[trackingErrorsOfInclassifySubTrial lastObject]).desc doubleValue];
					double teWhenBackToTracking = [((VFCustomEvent *)[trackingErrorsOfInclassifySubTrial objectAtIndex:0]).desc doubleValue];
					
					te.value = [decimalFormatter stringFromNumber:[NSNumber numberWithDouble:teWhenKeyIn - teWhenBackToTracking]];
				} else {
					te.value = @"NA";
				}
			} else {
				r3.value = @"NA";
				te.value = @"NA";
			}
			
			VFResponse *r4 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r4.measure = @"Preclassify Dwell Duration";
			r4.value = [[NSNumber numberWithInt:dwellDuration[0]] stringValue];
			
			VFResponse *r5 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r5.measure = @"Inclassify Dwell Duration";
			r5.value = [[NSNumber numberWithInt:dwellDuration[1]] stringValue];
			
			VFResponse *r6 = [NSEntityDescription insertNewObjectForEntityForName:@"Response" 
														   inManagedObjectContext:managedObjectContext];
			r6.measure = @"Inclassify Scan Path";
			r6.value = scanpath;
			
			[eachTrial addResponses:[NSSet setWithObjects:r1, r2, r3, r4, r5, r6, te, nil]];
		}
	}
	
	if (![managedObjectContext save:&error]) {
		NSLog(@"Save data failed at %@\n%@", [storeFileURL path], [error localizedFailureReason]);
	}
	
	NSLog(@"Process completed.\n\n\n");
}

- (void)output:(NSURL *)storeFileURL
{
	NSURL *outputFileURL = [NSURL fileURLWithPath:
							[[[storeFileURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"output"]];
	NSMutableString *output = [NSMutableString stringWithString:@""];
	
	NSArray *factorSortDesc = [NSArray arrayWithObject:
							   [[NSSortDescriptor alloc] initWithKey:@"factor" ascending:YES]];
	NSArray *measureSortDesc = [NSArray arrayWithObject:
								[[NSSortDescriptor alloc] initWithKey:@"measure" ascending:YES]];
	
	VFSession *session = [VFUtil fetchSessionWithMOC:managedObjectContext];
	NSArray *blocks = [[session.blocks allObjects]
					   sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
	
	NSString *sessionInfo = [session.subjectID stringByAppendingFormat:@"\t%@", session.sessionID];
	for (VFBlock *eachBlock in blocks) {
		NSMutableString *blockConditions = [NSMutableString stringWithString:@""];
		
		for (VFCondition *eachCondition in [[eachBlock.conditions allObjects] 
											sortedArrayUsingDescriptors:factorSortDesc]) {
			[blockConditions appendFormat:@"\t%@", eachCondition.level];
		}
		
		NSArray *trials = [[eachBlock.trials allObjects] 
						   sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
		for (VFTrial *eachTrial in trials) {
			NSMutableString *trialConditions = [NSMutableString stringWithString:@""];
			
			for (VFCondition *eachCondition in [[eachTrial.conditions allObjects] 
												sortedArrayUsingDescriptors:factorSortDesc]) {
				[trialConditions appendFormat:@"\t%@", eachCondition.level];
			}
			
			NSMutableString *trialResponses = [NSMutableString stringWithString:@""];
			for (VFResponse *eachResponse in [[eachTrial.responses allObjects] 
											  sortedArrayUsingDescriptors:measureSortDesc]) {
				[trialResponses appendFormat:@"\t%@", eachResponse.value];
				if (eachResponse.error != nil) {
					[trialResponses appendFormat:@"\t%@", eachResponse.error];
				}
			}
			
			[output appendFormat:@"%@\t%@\t%@%@%@%@\n", sessionInfo, eachBlock.ID, eachTrial.ID,
			 blockConditions, trialConditions, trialResponses];
		}
	}
	
	NSError *error;
	if (![output writeToURL:outputFileURL atomically:YES
				   encoding:NSUnicodeStringEncoding error:&error]) {
		// an error occurred
		NSLog(@"Error writing file at %@\n%@",
              [outputFileURL path], [error localizedFailureReason]);
	}
}

@end
