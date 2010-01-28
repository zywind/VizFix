// 
//  VFBlock.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFBlock.h"

#import "VFKeyboardEvent.h"
#import "VFTrial.h"
#import "VFFixation.h"
#import "VFAuditoryStimulus.h"
#import "VFCustomEvent.h"
#import "VFSession.h"
#import "VFCondition.h"
#import "VFGazeSample.h"
#import "VFVisualStimulus.h"

@implementation VFBlock 

@dynamic order;
@dynamic ID;
@dynamic startTime;
@dynamic endTime;
@dynamic keyboardEvents;
@dynamic trials;
@dynamic fixations;
@dynamic auditoryStimuli;
@dynamic customEvents;
@dynamic inSession;
@dynamic conditions;
@dynamic gazeSamples;
@dynamic visualStimuli;

- (BOOL)leaf
{
	return NO;
}

- (NSSet *)children
{
	return self.trials;
}

@end