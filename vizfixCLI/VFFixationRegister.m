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
		autoAOIDOV = 2.5;
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

- (void)registerFixation:(VFFixation *)aFixation
{
	aFixation.fixatedAOI = nil;
	NSArray *onScreenStimuli = [visualStimuliArray filteredArrayUsingPredicate:
								[VFUtil predicateForObjectsWithStartTime:aFixation.startTime 
																 endTime:aFixation.endTime]];
	
	for (VFVisualStimulus *eachStimulus in onScreenStimuli) {
		NSSet *onScreenFrames = [eachStimulus.frames filteredSetUsingPredicate:
								 [VFUtil predicateForObjectsWithStartTime:aFixation.startTime 
																  endTime:aFixation.endTime]];
		
		for (VFVisualStimulusFrame *eachFrame in onScreenFrames) {
			NSPoint center = NSMakePoint(eachFrame.location.x + eachStimulus.template.center.x, 
										 eachFrame.location.y + eachStimulus.template.center.y);
			
			NSSize autoAOISize = NSMakeSize([converter horizontalPixelsFromVisualAngles:autoAOIDOV], 
											[converter verticalPixelsFromVisualAngles:autoAOIDOV]);
			NSBezierPath *aoiPath = [VFUtil autoAOIAroundCenter:center withSize:autoAOISize];
			if ([aoiPath containsPoint:aFixation.location]) {
				[aFixation registerOnAOI:eachStimulus.ID];
				break;
			}
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
		[self registerFixation:fix];
	}
}
@end
