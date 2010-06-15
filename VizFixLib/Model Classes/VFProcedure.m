// 
//  VFTrial.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFProcedure.h"

@implementation VFProcedure 

@dynamic startTime;
@dynamic endTime;
@dynamic ID;
@dynamic parentProc;
@dynamic subProcs;
@dynamic conditions;
@dynamic statistics;

- (BOOL)leaf
{
	return NO;
}

@end
