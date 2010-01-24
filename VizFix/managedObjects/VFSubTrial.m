// 
//  VFSubTrial.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFSubTrial.h"

#import "VFTrial.h"

@implementation VFSubTrial 

@dynamic endTime;
@dynamic ID;
@dynamic startTime;
@dynamic inTrial;

- (BOOL)leaf
{
	return YES;
}

- (NSSet *)children
{
	return nil;
}


@end
