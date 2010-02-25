//
//  VFFixationRegister.m
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 2/3/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFFixationRegister.h"


@implementation VFFixationRegister

@synthesize customAOIs;
@synthesize autoAOIDOV;

- (id)initWithMOC:(NSManagedObjectContext *)anMOC
{	
	if (self = [super init]) {
		moc = anMOC;
		visualStimuliArray = [VFUtil fetchAllObjectsForName:@"VisualStimulus" fromMOC:moc];
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
	NSArray *onScreenStimuli = [visualStimuliArray filteredArrayUsingPredicate:
								[VFUtil predicateForObjectsWithStartTime:aFixation.startTime 
																 endTime:aFixation.endTime]];
	
	double minDistanceOfAll = autoAOIDOV;
	VFVisualStimulus *targetStimulus;
	
	for (VFVisualStimulus *eachStimulus in onScreenStimuli) {
		NSSet *onScreenFrames = [eachStimulus.frames filteredSetUsingPredicate:
								 [VFUtil predicateForObjectsWithStartTime:aFixation.startTime 
																  endTime:aFixation.endTime]];
		
		double minDistanceOfFixation = autoAOIDOV;
		NSPoint minCenter;
		double minH, minV;
		for (VFVisualStimulusFrame *eachFrame in onScreenFrames) {
			NSPoint center = NSMakePoint(eachFrame.location.x + eachStimulus.template.center.x, 
										 eachFrame.location.y + eachStimulus.template.center.y);
			
			double h = [converter horizontalVisualAnglesFromPixels:(aFixation.location.x - center.x)];
			double v = [converter verticalVisualAnglesFromPixels:(aFixation.location.y - center.y)];
			double dis = sqrt(h*h + v*v);
			if (dis < minDistanceOfFixation) {
				minDistanceOfFixation = dis;
				minH = h;
				minV = v;
				minCenter = center;
			}
		}
		
		if (minDistanceOfFixation < minDistanceOfAll) {
			targetStimulus = eachStimulus;
			aFixation.fixatedAOI = [NSString stringWithFormat:@"%@, %1.2f, %1.2f, %1.0f, %1.0f", 
									eachStimulus.ID, minH, minV, minCenter.x, minCenter.y];
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
	for (VFFixation *fix in [VFUtil fetchAllObjectsForName:@"Fixation" fromMOC:moc]) {
		[self registerFixationToClosestAOI:fix];
	}
}
@end
