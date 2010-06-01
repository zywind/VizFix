//
//  VFBlock.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFTrial;
@class VFSession;
@class VFCondition;


/**
	Stores information regarding an experimental structure, block.
 #ID, #startTime, #endTime are required properties. 
 A block may contain multiple trails. These trials should happen within a short period of time, 
 roughly about 1 minute to 10 minutes. A block contains lists for all kinds of events, 
 including gaze samples and fixations. VizFix loads all events of a block at a time, so its memory
 usage depends on how long a block is. 
 */
@interface VFBlock :  NSManagedObject
{
	
}
/**
 A string for identifying the block, will be displayed in the tree view.
 */
@property (nonatomic, retain) NSString * ID;
/**
 The start time of the block, in ms.
 */
@property (nonatomic, retain) NSNumber * startTime;
/**
 The end time of the block, in ms.
 */
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSSet* trials;
@property (nonatomic, retain) VFSession * inSession;
@property (nonatomic, retain) NSSet* conditions;

@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;

@end

@interface VFBlock (CoreDataGeneratedAccessors)

/**
	Add a trial object that occurred within the block.￼  @see VFTrial.
 */
- (void)addTrialsObject:(VFTrial *)value;
/**
	Remove a trial object.￼ @see VFTrial.
 */
- (void)removeTrialsObject:(VFTrial *)value;
- (void)addTrials:(NSSet *)value;
- (void)removeTrials:(NSSet *)value;

/**
	Add a block condition. @see VFCondition.
 */
- (void)addConditionsObject:(VFCondition *)value;
/**
	Remove a block condition. @see VFCondition.
 */
- (void)removeConditionsObject:(VFCondition *)value;
- (void)addConditions:(NSSet *)value;
- (void)removeConditions:(NSSet *)value;

@end

