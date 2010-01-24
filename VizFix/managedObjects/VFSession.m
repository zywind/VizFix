// 
//  VFSession.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFSession.h"

#import "VFVisualStimulusTemplate.h"
#import "VFBlock.h"

@implementation VFSession 

@dynamic screenResolutionHeight;
@dynamic screenDimensionHeight;
@dynamic sessionID;
@dynamic experiment;
@dynamic distanceToScreen;
@dynamic screenDimensionWidth;
@dynamic subjectID;
@dynamic gazeSampleRate;
@dynamic date;
@dynamic screenResolutionWidth;
@dynamic blocks;

- (BOOL)leaf
{
	return NO;
}

- (NSSet *)children
{
	return self.blocks;
}


- (NSString *)ID
{
	return self.sessionID;
}

@end
