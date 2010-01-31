//
//  VFDTFixationAlg.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFDTFixationAlg.h"


@implementation VFDTFixationAlg

@synthesize gazeSampleRate;
@synthesize radiusThreshold;

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{	

	}
	
	return self;
}

- (void)detectFixation:(NSArray *)gazeArray inMOC:(NSManagedObjectContext *)moc
{	
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
		
		NSArray *dispersionParams = [self dispersionOfGazes:ongoingFixationGazes];
		float dispersion = [[dispersionParams objectAtIndex:0] floatValue];
		NSPoint curCentroid = [self centroidOfGazes:ongoingFixationGazes];
		[ongoingFixationGazes sortUsingDescriptors:[VFUtil timeSortDescriptor]];
		VFGazeSample *earliestGaze = [ongoingFixationGazes objectAtIndex:0];
		
		if (dispersion >= self.radiusThreshold) {
			// I took the other method described in Karsh. Because I found removing the most deviant gaze sometiems has problem.
			[ongoingFixationGazes removeObject:earliestGaze];
			continue;
		}
		
		if (FLAG) {
			FLAG = NO;
			NSPoint prevCentroid = [self centroidOfGazes:previousFixationGazes];
			
			if ([VFUtil distanceBetweenThisPoint:prevCentroid andThatPoint:curCentroid] < self.radiusThreshold) {
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
								  andThatPoint:curCentroid] >= self.radiusThreshold) {
				numSuccessiveOutsideGaze++;
				if (numSuccessiveOutsideGaze == 1) {
					firstOutsideGaze = gaze;
					continue;
				} else {
					NSPoint centroidOfOutsideGazes;
					centroidOfOutsideGazes.x = (firstOutsideGaze.location.x + gaze.location.x) / 2;
					centroidOfOutsideGazes.y = (firstOutsideGaze.location.y + gaze.location.y) / 2;
					
					if ([VFUtil distanceBetweenThisPoint:centroidOfOutsideGazes
										  andThatPoint:curCentroid] >= self.radiusThreshold) {
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

- (NSUInteger)thresholdOfNumConsecutiveInvalidSamples
{
	return round(330.0 / (1000.0 / (float)gazeSampleRate));
}

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

- (NSArray *)dispersionOfGazes:(NSArray *)gazes
{
	NSPoint centroid = [self centroidOfGazes:gazes];
	
	float dispersion = 0;
	VFGazeSample *deviantGaze;
	for (VFGazeSample *eachGaze in gazes)
	{
		float distance = [VFUtil distanceBetweenThisPoint:centroid 
										   andThatPoint:eachGaze.location];
		if (distance > dispersion) {
			dispersion = distance;
			deviantGaze = eachGaze;
		}
	}
	
	return [NSArray arrayWithObjects:[NSNumber numberWithFloat:dispersion], deviantGaze, nil];
}



@end
