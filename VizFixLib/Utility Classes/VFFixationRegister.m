/********************************************************************
 File:   VFFixationRegister.m
 
 Created:  2/3/10
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

#import "VFFixationRegister.h"

#import "VFVisualAngleConverter.h"
#import "VFFixation.h"
#import "VFFetchHelper.h"

#import "VFVisualStimulus.h"
#import "VFVisualStimulusFrame.h"
#import "VFVisualStimulusTemplate.h"

@implementation VFFixationRegister

@synthesize customAOIs;
@synthesize deviationThreshold;

- (id)initWithMOC:(NSManagedObjectContext *)anMOC
{	
	if (self = [super init]) {
		moc = anMOC;
		fetchHelper = [[VFFetchHelper alloc] initWithMOC:moc];
		visualStimuliArray = [fetchHelper fetchAllObjectsForName:@"VisualStimulus"];
		converter = [[VFVisualAngleConverter alloc] initWithMOC:moc];
		deviationThreshold = 5.5;
	}
    return self;
}

- (void)useVisualStimuliOfCategoriesAsAOI:(NSArray *)categories
{
	NSMutableArray *allVSs = [NSMutableArray arrayWithCapacity:10];
	for (NSString *eachCategory in categories) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"template.category LIKE %@", eachCategory];
		[allVSs addObjectsFromArray:[visualStimuliArray filteredArrayUsingPredicate:predicate]];
	}
	
	visualStimuliArray = [NSArray arrayWithArray:allVSs];
}

- (void)registerFixationToClosestAOI:(VFFixation *)aFixation
{
	aFixation.fixatedAOI = nil;
	// The intention of a fixation should only be looking at something happened before that fixation.
	NSArray *onScreenStimuli = [visualStimuliArray filteredArrayUsingPredicate:
								[NSPredicate predicateWithFormat:@"(startTime <= %@ AND endTime >= %@)", 
								 aFixation.startTime, aFixation.startTime]];
	
	double deviationThresholdInPix = [converter pixelsFromVisualAngles:deviationThreshold];
	
	double minDistanceOfAll = deviationThresholdInPix;
	
	VFVisualStimulus *targetStimulus;
	
	for (VFVisualStimulus *eachStimulus in onScreenStimuli) {
		NSSet *onScreenFrames = [eachStimulus.frames filteredSetUsingPredicate:
								 [NSPredicate predicateWithFormat:@"(startTime <= %@ AND endTime >= %@)", 
								  aFixation.startTime, aFixation.startTime]];
		
		double minDistanceOfFixation = deviationThresholdInPix;
		NSPoint minCenter;
		for (VFVisualStimulusFrame *eachFrame in onScreenFrames) {
			NSPoint center = NSMakePoint(eachFrame.location.x + eachStimulus.template.fixationPoint.x, 
										 eachFrame.location.y + eachStimulus.template.fixationPoint.y);
			
			double h = aFixation.location.x - center.x;
			double v = aFixation.location.y - center.y;
			double dis = sqrt(h*h + v*v);
			if (dis < minDistanceOfFixation) {
				minDistanceOfFixation = dis;
				minCenter = center;
			}
		}
		
		if (minDistanceOfFixation < minDistanceOfAll) {
			minDistanceOfAll = minDistanceOfFixation;
			targetStimulus = eachStimulus;
//			aFixation.fixatedAOI = [NSString stringWithFormat:@"%@, %1.2f, %1.2f, %1.0f, %1.0f", 
//									eachStimulus.ID, aFixation.location.x - minCenter.x, aFixation.location.y - minCenter.y, minCenter.x, minCenter.y];
			
//			aFixation.fixatedAOI = eachStimulus.ID;
			
			aFixation.fixatedAOI = [NSString stringWithFormat:@"%@, %d, %1.2f, %1.2f, %1.0f, %1.0f", 
									eachStimulus.ID, [aFixation.endTime intValue] - [aFixation.startTime intValue], 
									aFixation.location.x, aFixation.location.y, minCenter.x, minCenter.y];
		}
	}
	
	// If the fixation is not fixated on any on screen stimulus, then see if it is on custom AOIs.
	if (aFixation.fixatedAOI == nil) {
		for (id key in customAOIs) {
			NSBezierPath *aoiPath = [customAOIs objectForKey:key];
			if ([aoiPath containsPoint:aFixation.location]) {
				aFixation.fixatedAOI = [NSString stringWithFormat:@"%@, %d, %1.2f, %1.2f, NA, NA", 
										key, [aFixation.endTime intValue] - [aFixation.startTime intValue], 
										aFixation.location.x, aFixation.location.y];
			}
		}
		// If it's still nil, it's on "Other" area.
		if (aFixation.fixatedAOI == nil) {
			aFixation.fixatedAOI = [NSString stringWithFormat:@"Other, %d, %1.2f, %1.2f, NA, NA", 
									[aFixation.endTime intValue] - [aFixation.startTime intValue], 
									aFixation.location.x, aFixation.location.y];
		}
	}
}

- (void)registerAllFixations
{
	for (VFFixation *fix in [fetchHelper fetchAllObjectsForName:@"Fixation"]) {
		[self registerFixationToClosestAOI:fix];
	}
}
@end
