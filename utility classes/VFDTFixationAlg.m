//
//  VFDTFixationAlg.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFDTFixationAlg.h"

#import "VFUtil.h"
#import "VFVisualAngleConverter.h"

#import "VFSession.h"
#import "VFGazeSample.h"
#import "VFFixation.h"

@implementation VFDTFixationAlg

- (void)detectAllFixationsInMOC:(NSManagedObjectContext *)moc withRadiusThresholdInDOV:(double)aRadius
{
	VFSession *session = [VFUtil fetchSessionWithMOC:moc];
	VFVisualAngleConverter *DOVConverter = 
	[[VFVisualAngleConverter alloc] initWithDistanceToScreen:[session.distanceToScreen intValue]
											screenResolution:session.screenResolution 
											 screenDimension:session.screenDimension];	
	gazeSampleRate = [session.gazeSampleRate doubleValue];
	
	radiusThreshold = sqrt([DOVConverter horizontalPixelsFromVisualAngles:aRadius] 
						   * [DOVConverter verticalPixelsFromVisualAngles:aRadius]);
	
	// Retrieve gazes
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"GazeSample" inManagedObjectContext:moc];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	[request setSortDescriptors:[VFUtil timeSortDescriptor]];
	
	NSError *error;
	NSArray *gazeArray = [moc executeFetchRequest:request error:&error];
	if (gazeArray == nil)
	{
		NSLog(@"Fetch gaze samples failed.\n%@", [error localizedDescription]);
		return;
	}
	
	[self detectFixation:gazeArray];
	gazeArray = nil;
}

- (void)detectFixation:(NSArray *)gazeArray
{	
	BOOL FLAG = NO;
	NSUInteger numConsecutiveInvalidSamples = 0;
	
	NSMutableArray *ongoingFixationGazes = [NSMutableArray arrayWithCapacity:20];
	NSMutableArray *previousFixationGazes = [NSMutableArray arrayWithCapacity:20];
	
	NSManagedObjectContext * moc = [[gazeArray objectAtIndex:0] managedObjectContext];
	
	for (int i = 0; i < [gazeArray count]; i++)
	{
		VFGazeSample *gaze = [gazeArray objectAtIndex:i];
		
		// Establish the onset of a fixation
		if (![gaze.valid boolValue]) {
			numConsecutiveInvalidSamples++;
			if (numConsecutiveInvalidSamples >= [self thresholdOfNumConsecutiveInvalidSamples])
			{
				FLAG = NO;
				numConsecutiveInvalidSamples = 0;
				[ongoingFixationGazes removeAllObjects];
				[previousFixationGazes removeAllObjects];
			}
			continue;
		}
		
		[ongoingFixationGazes addObject:gaze];
		numConsecutiveInvalidSamples = 0;
		
		if ([ongoingFixationGazes count] < [self minNumInFixation]) {
			continue;
		}
		
		float dispersion = [self dispersionOfGazes:ongoingFixationGazes];
		NSPoint curCentroid = [self centroidOfGazes:ongoingFixationGazes];
		[ongoingFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		VFGazeSample *earliestGaze = [ongoingFixationGazes objectAtIndex:0];
		
		if (dispersion >= radiusThreshold) {
			// I took the other method described in Karsh. Because I found removing the most deviant gaze sometiems has problem.
			[ongoingFixationGazes removeObject:earliestGaze];
			continue;
		}
		
		if (FLAG) {
			FLAG = NO;
			NSPoint prevCentroid = [self centroidOfGazes:previousFixationGazes];
			
			if ([VFUtil distanceBetweenThisPoint:prevCentroid andThatPoint:curCentroid] < radiusThreshold) {
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
				if (numConsecutiveInvalidSamples < [self thresholdOfNumConsecutiveInvalidSamples])
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
									andThatPoint:curCentroid] >= radiusThreshold) {
				numSuccessiveOutsideGaze++;
				if (numSuccessiveOutsideGaze == 1) {
					firstOutsideGaze = gaze;
					continue;
				} else {
					NSPoint centroidOfOutsideGazes;
					centroidOfOutsideGazes.x = (firstOutsideGaze.location.x + gaze.location.x) / 2;
					centroidOfOutsideGazes.y = (firstOutsideGaze.location.y + gaze.location.y) / 2;
					
					if ([VFUtil distanceBetweenThisPoint:centroidOfOutsideGazes
											andThatPoint:curCentroid] >= radiusThreshold) {
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
		NSPoint prevCentroid = [self centroidOfGazes:previousFixationGazes];
		
		[previousFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		prevFixation.startTime = ((VFGazeSample *)[previousFixationGazes objectAtIndex:0]).time;
		prevFixation.endTime = ((VFGazeSample *)[previousFixationGazes lastObject]).time;
		
		prevFixation.location = prevCentroid;
		
	}
	
	if ([ongoingFixationGazes count] >= [self minNumInFixation]) {
		VFFixation *ongoingFixation = [NSEntityDescription 
									   insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
		NSPoint curCentroid = [self centroidOfGazes:ongoingFixationGazes];
		
		[ongoingFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		ongoingFixation.startTime = ((VFGazeSample *)[ongoingFixationGazes objectAtIndex:0]).time;
		ongoingFixation.endTime = ((VFGazeSample *)[ongoingFixationGazes lastObject]).time;
		
		ongoingFixation.location = curCentroid;
	}
}

// 330.0 ms is estimated from Karsh's 12 consecutive invalid samples, in which their sample rate is 60 HZ.
- (NSUInteger)thresholdOfNumConsecutiveInvalidSamples
{
	return round(330.0 / (1000.0 / (float)gazeSampleRate));
}

// Assuming the minimum fixation duration is 100.0 ms.
- (NSUInteger)minNumInFixation
{
	return round(100.0 / (1000.0 / (float)gazeSampleRate));
}

- (NSPoint)centroidOfGazes:(NSArray *)gazes
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

- (float)dispersionOfGazes:(NSArray *)gazes
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
