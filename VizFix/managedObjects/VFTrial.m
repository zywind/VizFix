// 
//  VFTrial.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFTrial.h"

#import "VFBlock.h"
#import "VFSubTrial.h"
#import "VFCondition.h"
#import "VFResponse.h"

@implementation VFTrial 

@dynamic startTime;
@dynamic endTime;
@dynamic ID;
@dynamic inBlock;
@dynamic subTrials;
@dynamic conditions;
@dynamic responses;

- (BOOL)leaf
{
	return NO;
}

- (NSSet *)children
{
	return self.subTrials;
}

@end
