//
//  VFFixationRegister.m
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 2/3/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFFixationRegister.h"

#import "VFVisualAngleConverter.h"
#import "VFFixation.h"
#import "VFFetchHelper.h"

#import "VFVisualStimulus.h"
#import "VFVisualStimulusFrame.h"
#import "VFVisualStimulusTemplate.h"

@implementation VFFixationRegister

@synthesize customAOIs;
@synthesize autoAOIDOV;

- (id)initWithMOC:(NSManagedObjectContext *)anMOC
{	
	if (self = [super init]) {
		moc = anMOC;
		fetchHelper = [[VFFetchHelper alloc] initWithMOC:moc];
		visualStimuliArray = [fetchHelper fetchAllObjectsForName:@"VisualStimulus"];
		converter = [[VFVisualAngleConverter alloc] initWithMOC:moc];
		autoAOIDOV = 5.5;
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
	
	double deviationThreshold = [converter pixelsFromVisualAngles:autoAOIDOV];
	
	double minDistanceOfAll = deviationThreshold;
	VFVisualStimulus *targetStimulus;
	
	for (VFVisualStimulus *eachStimulus in onScreenStimuli) {
		NSSet *onScreenFrames = [eachStimulus.frames filteredSetUsingPredicate:
								 [NSPredicate predicateWithFormat:@"(startTime <= %@ AND endTime >= %@)", 
								  aFixation.startTime, aFixation.startTime]];
		
		double minDistanceOfFixation = deviationThreshold;
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
			aFixation.fixatedAOI = eachStimulus.ID;
		}
	}
	
	// If the fixation is not fixated on any on screen stimulus, then see if it is on custom AOIs.
	if (aFixation.fixatedAOI == nil) {
		for (id key in customAOIs) {
			NSBezierPath *aoiPath = [customAOIs objectForKey:key];
			if ([aoiPath containsPoint:aFixation.location]) {
				[aFixation registerOnAOI:key];
			}
		}
		// If it's still nil, it's on "Other" area.
		if (aFixation.fixatedAOI == nil) {
			[aFixation registerOnAOI:@"Other"];
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
