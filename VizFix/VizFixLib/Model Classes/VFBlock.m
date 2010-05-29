// 
//  VFBlock.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFBlock.h"

@implementation VFBlock 

@dynamic ID;
@dynamic startTime;
@dynamic endTime;
@dynamic trials;
@dynamic inSession;
@dynamic conditions;

- (BOOL)leaf
{
	return NO;
}

- (NSSet *)children
{
	return self.trials;
}

@end
