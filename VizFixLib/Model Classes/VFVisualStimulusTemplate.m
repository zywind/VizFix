// 
//  VFVisualStimulusTemplate.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFVisualStimulusTemplate.h"


@implementation VFVisualStimulusTemplate 

@dynamic imageFilePath;
@dynamic zorder;
@dynamic category;
@dynamic outline;
@dynamic fillColor;
@dynamic strokeColor;
@dynamic ofVisualStimuli;

- (NSPoint)center
{
	NSRect bounds = [self.outline bounds];
	return NSMakePoint(NSMidX(bounds), NSMidY(bounds));
}
@end
