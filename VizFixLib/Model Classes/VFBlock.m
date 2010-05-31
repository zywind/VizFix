// 
//  VFBlock.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFBlock.h"

/*! 
 * @brief what is a Block?
 * Represents a block of a session. A block may contain multiple trails. These trials should happen within 
 * a short period of time, roughly about 1 minute to 10 minutes. A block contains lists for all kinds of
 * events, including gaze samples and fixations. VizFix loads all events of a block at a time, so its memory
 * usage depends on how long a block is.
 */
@implementation VFBlock 
/*!
 A string for identifying the block. This string will be displayed in the tree view.
 */
@dynamic ID;
/*!
 The start time of the block, in ms.
 */
@dynamic startTime;
/*!
 The end time of the block, in ms.
 */
@dynamic endTime;
/*!
 Required. Represents all the trials of this block.
 */
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
