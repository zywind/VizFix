//
//  VFDispersionAlgorithm.m
//  VizFixX
//
//  Created by Tim Halverson on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "VFDispersionAlgorithm.h"

@implementation VFDispersionAlgorithm

@synthesize minFixSamples;
@synthesize radius;

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{	
	
	}
	
	return self;
}

//	This method is called once for every sample (in correct temporal order) that will be analyzed for fixations.
//	The dispersion based algorithm defined here has the following properties:
//	1) A sample is considered to be within the dispersion threshold and part of an ongoing
//		fixation if the sample is less than 'radius' units (usually pixels) from the center
//		of gravity of all previous, contiguous samples that are in the current potential fixation.
//	2) To accomodate blinks, invalid (e.g. eye not found) samples are considered part of an ongoing
//		fixation if:
//			a) the next valid sample is less than 'radius' units from the center of gravity of the
//				current fixation.
//			b) the number of contiguous invalid samples is less than 'minFixSamples'.
//	3) To accomodate noise, a single sample that is greater than 'radius' units from the center
//		of gravity of the current fixation is considered part of the current fixation if the
//		following sample falls back with the 'radius' units.
//	Note that if invalid or noisy samples are included in a fixation, the location of these samples
//	are not used to determine the ongoing (or final) center of gravity for the current fixation.
- (void)detectFixation:(NSArray *)gazeArray inMOC:(NSManagedObjectContext *)moc
{
	BOOL firstSample = YES;
	int nSamplesInFix = 0;
	int fixationStartTime = 0;
	int fixCenterX, fixCenterY;
	BOOL noisySample = NO;
	int numSamplesEyeNotFound = 0;
	int noisySampleNumber = 0;
	int noisySampleX = 0;
	int noisySampleY = 0;
	
	for (VFGazeSample *gaze in gazeArray)
	{
		//	Get the data passed in the 'sample' dictionary.
		int gazeTime = [gaze.time intValue];
		int x = [gaze.location.x intValue];
		int y = [gaze.location.y intValue];
		BOOL eyeFound = [gaze.valid boolValue];
		
		if(eyeFound)
		{
			//	Reset the number of samples the eye has not been found
			numSamplesEyeNotFound = 0;
			
			//	If there is not an ongoing potential fixation
			//	Note: This is a special case that applies
			//	when this method is first called or when
			//	the last sample resulted in too many
			//	contiguous invalid samples (i.e. a fixation
			//	was declared due to numSamplesEyeNotFound
			//	exceeding minFixSamples).
			if(firstSample)
			{
				nSamplesInFix = 1;
				fixationStartTime = gazeTime;
				
				fixCenterX = x;
				fixCenterY = y;
				
				firstSample = NO;
			} 
			else 
			{
				//	If the the new sample is inside the ongoing potential
				//	fixation's dispersion threshold
				if([self distanceBetweenThisPoint:NSMakePoint(fixCenterX, fixCenterY) 
									 andThatPoint:NSMakePoint(x, y)] <= [self radius])
				{
					//	Reset the noisy sample flag
					noisySample = NO;
					
					//	Update ongoing fixation
					fixCenterX = ((fixCenterX * nSamplesInFix) + x) / (nSamplesInFix + 1);
					fixCenterY = ((fixCenterY * nSamplesInFix) + y) / (nSamplesInFix + 1);
					nSamplesInFix++;
				}
				else
				{
					//	The new sample is outside the ongoing potential fixation's
					//	dispersion threshold.
					
					//	If the previous sample was *not* outside the dispersion threshold,
					//	ignore this one sample to accomodate noise.
					if(!noisySample)
					{	
						//	Count (for now) this noisy sample
						nSamplesInFix++;
						
						//	Set the flag indicating that the last sample
						//	was a noisy sample.
						noisySample = YES;
						noisySampleNumber = gazeTime;
						noisySampleX = x;
						noisySampleY = y;
					} 
					else {
						//	If the potential fixation's duration is less than the min
						if((nSamplesInFix - numSamplesEyeNotFound - noisySample) >= [self minFixSamples])
						{
							
							VFFixation *newFixation = [NSEntityDescription 
													   insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
							//	The end of a fixation has been found
							newFixation.location.x = [NSNumber numberWithInt:fixCenterX];
							newFixation.location.y = [NSNumber numberWithInt:fixCenterY];
							newFixation.timeSpan.startTime = [NSNumber numberWithInt:fixationStartTime];
							newFixation.timeSpan.endTime = [NSNumber numberWithInt:gazeTime];
						}
						
						//	If we get to this point, we know that the previous sample
						//	was considered 'noisy'. So, if the current sample is
						//	close enough to the previous sample, then include
						//	both in the ongoing fixation. Otherwise, only include
						//	the current sample.
						fixCenterX = noisySampleX;
						fixCenterY = noisySampleY;
						if([self distanceBetweenThisPoint:NSMakePoint(fixCenterX, fixCenterY) 
											 andThatPoint:NSMakePoint(x, y)] <= self.radius)
						{
							nSamplesInFix = 2;
							startingSample = noisySampleNumber;
							
							fixCenterX = (noisySampleX + x) / 2;
							fixCenterY = (noisySampleY + y) / 2;
						}
						else
						{
							nSamplesInFix = 1;
							fixationStartTime = gazeTime;
							
							fixCenterX = x;
							fixCenterY = y;
						}
						
						numSamplesEyeNotFound = 0;
						noisySample = NO;
						
						continue;
					}
				}
			}
			else
			{
				//	If we have not received a valid first sample, do nothing
				if(firstSample)
					continue;
				else
				{
					numSamplesEyeNotFound++;
					nSamplesInFix++;
					
					//	If the lost eye samples exceeds min fixation samples...
					if(numSamplesEyeNotFound >= [self minFixSamples])
					{
						NSDictionary *toReturn;
						
						//	If there was a fixation prior to the eye being lost,
						//	declare that fixation complete without including the
						//	latest contiguous lost samples in the duration.
						if((nSamplesInFix - numSamplesEyeNotFound - noisySample) < [self minFixSamples])
							toReturn = nil;
						else {
							VFFixation *newFixation = [NSEntityDescription 
													   insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
							//	The end of a fixation has been found
							newFixation.location.x = [NSNumber numberWithInt:fixCenterX];
							newFixation.location.y = [NSNumber numberWithInt:fixCenterY];
							newFixation.timeSpan.startTime = [NSNumber numberWithInt:fixationStartTime];
							newFixation.timeSpan.endTime = 0;						
						}					
						noisySample = NO;
						firstSample = YES;
						
						continue;
					}
					else
						continue;
				}
			}
		}
	}
	
	
	//	Special end case
	//	If there are no more samples, return a fixation if there is one ongoing.
	if((nSamplesInFix - numSamplesEyeNotFound - noisySample) >= [self minFixSamples])
	{
		VFFixation *newFixation = [NSEntityDescription 
								   insertNewObjectForEntityForName:@"Fixation" inManagedObjectContext:moc];
		//	The end of a fixation has been found
		newFixation.location.x = [NSNumber numberWithInt:fixCenterX];
		newFixation.location.y = [NSNumber numberWithInt:fixCenterY];
		newFixation.timeSpan.startTime = [NSNumber numberWithInt:fixationStartTime];
		newFixation.timeSpan.endTime = 0;
	}
}
//	Calculates the distance between (x,y) and the
//	current fixation's center of gravity
- (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point
{
	return sqrt(pow(point.x - center.x, 2.0) + pow(point.y - center.y, 2.0));
}

@end
