/********************************************************************
 File:   VFDTFixationAlg.m
 
 Created:  1/18/10
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

#import "VFDTFixationAlg.h"

#import "VFUtil.h"
#import "VFVisualAngleConverter.h"

#import "VFSession.h"
#import "VFGazeSample.h"
#import "VFFixation.h"
#import "VFFetchHelper.h"

// Dispersion Threshold Fixation Detection algorithm

@implementation VFDTFixationAlg

+ (void)detectFixation:(NSArray *)gazeArray withDispersionThreshold:(double)DTInDov andMinFixationDuration:(double)minFixationDuration;
{	
	NSManagedObjectContext * moc = [[gazeArray objectAtIndex:0] managedObjectContext];

	VFVisualAngleConverter *DOVConverter = [[VFVisualAngleConverter alloc] initWithMOC:moc];
	
	VFFetchHelper *fetchHelper = [[VFFetchHelper alloc] initWithMOC:moc];
	VFSession *session = [fetchHelper session];
    session.fixationDetectionDispersionThreshold = [NSNumber numberWithDouble:DTInDov];
    session.fixationDetectionMinimumDuration = [NSNumber numberWithDouble:minFixationDuration];
	
	double gazeSampleRate = [session.gazeSampleRate doubleValue];
	
	// 330.0 ms is estimated from Karsh's 12 consecutive invalid samples, in which their sample rate is 60 HZ.
	double dispersionThreshold = [DOVConverter pixelsFromVisualAngles:DTInDov];
	
	int maxNumConsecutiveInvalidSamples = round(330.0 / (1000.0 / gazeSampleRate));
	
	int minNumInFixation = round(minFixationDuration / (1000.0 / gazeSampleRate));
	
	BOOL FLAG = NO;
	NSUInteger numConsecutiveInvalidSamples = 0;
	
	NSMutableArray *ongoingFixationGazes = [NSMutableArray arrayWithCapacity:20];
	NSMutableArray *previousFixationGazes = [NSMutableArray arrayWithCapacity:20];
	
	
	for (int i = 0; i < [gazeArray count]; i++)
	{
		VFGazeSample *gaze = [gazeArray objectAtIndex:i];
		
		// Establish the onset of a fixation
		if (![gaze.valid boolValue]) {
			numConsecutiveInvalidSamples++;
			if (numConsecutiveInvalidSamples >= maxNumConsecutiveInvalidSamples)
			{
				FLAG = NO;
				numConsecutiveInvalidSamples = 0;
				[ongoingFixationGazes removeAllObjects];
				
				// 9-6-10 Make the previous fixation.  Before, I simply removed the gazes in the previous fixation, which 
				// leads to a bug.
				if ([previousFixationGazes count] >= minNumInFixation) {
					VFFixation *prevFixation = [NSEntityDescription 
												insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
					[previousFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
					prevFixation.startTime = ((VFGazeSample *)[previousFixationGazes objectAtIndex:0]).time;
					prevFixation.endTime = ((VFGazeSample *)[previousFixationGazes lastObject]).time;
					
					prevFixation.location = [VFDTFixationAlg centroidOfGazes:previousFixationGazes];
				}
				
			    [previousFixationGazes removeAllObjects];
			}
			continue;
		}
		
		[ongoingFixationGazes addObject:gaze];
		numConsecutiveInvalidSamples = 0;
		
		if ([ongoingFixationGazes count] < minNumInFixation) {
			continue;
		}
		
		float dispersion = [VFDTFixationAlg dispersionOfGazes:ongoingFixationGazes];
		NSPoint curCentroid = [VFDTFixationAlg centroidOfGazes:ongoingFixationGazes];
		[ongoingFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		VFGazeSample *earliestGaze = [ongoingFixationGazes objectAtIndex:0];
		
		if (dispersion >= dispersionThreshold) {
			// I took the other method described in Karsh. Because I found removing the most deviant gaze sometiems has problem.
			[ongoingFixationGazes removeObject:earliestGaze];
			continue;
		}
		
		if (FLAG) {
			FLAG = NO;
			NSPoint prevCentroid = [VFDTFixationAlg centroidOfGazes:previousFixationGazes];
			
			if ([VFUtil distanceBetweenThisPoint:prevCentroid andThatPoint:curCentroid] < dispersionThreshold) {
				[ongoingFixationGazes addObjectsFromArray:previousFixationGazes];
				// Go to 2.
			} else {
				// make the previous fixation.
				VFFixation *prevFixation = [NSEntityDescription 
											insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
				[previousFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
				prevFixation.startTime = ((VFGazeSample *)[previousFixationGazes objectAtIndex:0]).time;
				prevFixation.endTime = ((VFGazeSample *)[previousFixationGazes lastObject]).time;
				
				prevFixation.location = prevCentroid;
				
			}
			
			[previousFixationGazes removeAllObjects];
		}
		
		// The onset of the ongoing fixation is established.
		// Now we are to determine the end of the fixation.
		int numSuccessiveOutsideGaze = 0;
		VFGazeSample *firstOutsideGaze;
		for (i = i + 1; i < [gazeArray count]; i++) {
			gaze = [gazeArray objectAtIndex:i];
			if (![gaze.valid boolValue]) {
				numConsecutiveInvalidSamples++;
				if (numConsecutiveInvalidSamples < maxNumConsecutiveInvalidSamples)
				{
					// Make the ongoing fixatin.
					VFFixation *ongoingFixation = [NSEntityDescription 
												   insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
					
					[ongoingFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
					
					ongoingFixation.startTime = ((VFGazeSample *)[ongoingFixationGazes objectAtIndex:0]).time;
					ongoingFixation.endTime = ((VFGazeSample *)[ongoingFixationGazes lastObject]).time;
					
					ongoingFixation.location = curCentroid;
					
					FLAG = NO;
					numConsecutiveInvalidSamples = 0;
					[ongoingFixationGazes removeAllObjects];
					
					break;
				} else {
					continue;
				}
			}
			
			numConsecutiveInvalidSamples = 0;
			if ([VFUtil distanceBetweenThisPoint:gaze.location 
									andThatPoint:curCentroid] >= dispersionThreshold) {
				numSuccessiveOutsideGaze++;
				if (numSuccessiveOutsideGaze == 1) {
					firstOutsideGaze = gaze;
					continue;
				} else {
					NSPoint centroidOfOutsideGazes;
					centroidOfOutsideGazes.x = (firstOutsideGaze.location.x + gaze.location.x) / 2;
					centroidOfOutsideGazes.y = (firstOutsideGaze.location.y + gaze.location.y) / 2;
					
					if ([VFUtil distanceBetweenThisPoint:centroidOfOutsideGazes
											andThatPoint:curCentroid] >= dispersionThreshold) {
						[previousFixationGazes addObjectsFromArray:ongoingFixationGazes];
						[ongoingFixationGazes removeAllObjects];
						
						[ongoingFixationGazes addObject:firstOutsideGaze];
						[ongoingFixationGazes addObject:gaze];
						
						FLAG = YES;
						break;
					} else {
						numSuccessiveOutsideGaze = 0;
						[ongoingFixationGazes addObject:firstOutsideGaze];
						[ongoingFixationGazes addObject:gaze];
					}
				}
			} else {
				numSuccessiveOutsideGaze = 0;
				[ongoingFixationGazes addObject:gaze];
			}
		}
	}
	
	if ([previousFixationGazes count] != 0) {
		VFFixation *prevFixation = [NSEntityDescription 
									insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
		NSPoint prevCentroid = [VFDTFixationAlg centroidOfGazes:previousFixationGazes];
		
		[previousFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		prevFixation.startTime = ((VFGazeSample *)[previousFixationGazes objectAtIndex:0]).time;
		prevFixation.endTime = ((VFGazeSample *)[previousFixationGazes lastObject]).time;
		
		prevFixation.location = prevCentroid;
		
	}
	
	if ([ongoingFixationGazes count] >= minNumInFixation) {
		VFFixation *ongoingFixation = [NSEntityDescription 
									   insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
		NSPoint curCentroid = [VFDTFixationAlg centroidOfGazes:ongoingFixationGazes];
		
		[ongoingFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		ongoingFixation.startTime = ((VFGazeSample *)[ongoingFixationGazes objectAtIndex:0]).time;
		ongoingFixation.endTime = ((VFGazeSample *)[ongoingFixationGazes lastObject]).time;
		
		ongoingFixation.location = curCentroid;
	}
}

+ (NSPoint)centroidOfGazes:(NSArray *)gazes
{
	NSPoint centroid = NSMakePoint(0.0f, 0.0f);
	for (VFGazeSample *eachGaze in gazes)
	{
		centroid.x += eachGaze.location.x;
		centroid.y += eachGaze.location.y;
	}
	centroid.x = centroid.x / [gazes count];
	centroid.y = centroid.y / [gazes count];
	
	return centroid;
}

+ (float)dispersionOfGazes:(NSArray *)gazes
{
	NSPoint centroid = [self centroidOfGazes:gazes];
	
	float dispersion = 0;
	for (VFGazeSample *eachGaze in gazes)
	{
		float distance = [VFUtil distanceBetweenThisPoint:centroid 
											 andThatPoint:eachGaze.location];
		if (distance > dispersion) {
			dispersion = distance;
		}
	}
	
	return dispersion;
}

@end
