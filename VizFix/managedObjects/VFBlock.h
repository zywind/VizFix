//
//  VFBlock.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFKeyboardEvent;
@class VFTrial;
@class VFFixation;
@class VFAuditoryStimulus;
@class VFCustomEvent;
@class VFSession;
@class VFCondition;
@class VFGazeSample;
@class VFVisualStimulus;

/*!
 Represents a block of a session. A block may contain multiple trails. These trials should happen within 
 a short period of time, roughly about 1 minute to 10 minutes. A block contains lists for all kinds of
 events, including gaze samples and fixations. VizFix loads all events of a block at a time, so its memory
 usage depends on how long a block is.
 */
@interface VFBlock :  NSManagedObject  
{
}

/*!
 Indicates the position index of this block in the session's block list.
 */
@property (nonatomic, retain) NSNumber * order;
/*!
 A string for identifying the block. This string will be displayed in the tree view.
 */
@property (nonatomic, retain) NSString * ID;
/*!
 The start time of the block, in ms.
 */
@property (nonatomic, retain) NSNumber * startTime;
/*!
 The end time of the block, in ms.
 */
@property (nonatomic, retain) NSNumber * endTime;
/*!
 Optional. Contains all the keyboard events happened in this block. Note that there is no inverse
 relationship in the VFKeyboardEvent object to indicate which block it is in.
 */
@property (nonatomic, retain) NSSet* keyboardEvents;
/*!
 Required. Represents all the trials of this block.
 */
@property (nonatomic, retain) NSSet* trials;
@property (nonatomic, retain) NSSet* fixations;
@property (nonatomic, retain) NSSet* auditoryStimuli;
@property (nonatomic, retain) NSSet* customEvents;
@property (nonatomic, retain) VFSession * inSession;
@property (nonatomic, retain) NSSet* conditions;
@property (nonatomic, retain) NSSet* gazeSamples;
@property (nonatomic, retain) NSSet* visualStimuli;
@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;

@end


@interface VFBlock (CoreDataGeneratedAccessors)
- (void)addKeyboardEventsObject:(VFKeyboardEvent *)value;
- (void)removeKeyboardEventsObject:(VFKeyboardEvent *)value;
- (void)addKeyboardEvents:(NSSet *)value;
- (void)removeKeyboardEvents:(NSSet *)value;

- (void)addTrialsObject:(VFTrial *)value;
- (void)removeTrialsObject:(VFTrial *)value;
- (void)addTrials:(NSSet *)value;
- (void)removeTrials:(NSSet *)value;

- (void)addFixationsObject:(VFFixation *)value;
- (void)removeFixationsObject:(VFFixation *)value;
- (void)addFixations:(NSSet *)value;
- (void)removeFixations:(NSSet *)value;

- (void)addAuditoryStimuliObject:(VFAuditoryStimulus *)value;
- (void)removeAuditoryStimuliObject:(VFAuditoryStimulus *)value;
- (void)addAuditoryStimuli:(NSSet *)value;
- (void)removeAuditoryStimuli:(NSSet *)value;

- (void)addCustomEventsObject:(VFCustomEvent *)value;
- (void)removeCustomEventsObject:(VFCustomEvent *)value;
- (void)addCustomEvents:(NSSet *)value;
- (void)removeCustomEvents:(NSSet *)value;

- (void)addConditionsObject:(VFCondition *)value;
- (void)removeConditionsObject:(VFCondition *)value;
- (void)addConditions:(NSSet *)value;
- (void)removeConditions:(NSSet *)value;

- (void)addGazeSamplesObject:(VFGazeSample *)value;
- (void)removeGazeSamplesObject:(VFGazeSample *)value;
- (void)addGazeSamples:(NSSet *)value;
- (void)removeGazeSamples:(NSSet *)value;

- (void)addVisualStimuliObject:(VFVisualStimulus *)value;
- (void)removeVisualStimuliObject:(VFVisualStimulus *)value;
- (void)addVisualStimuli:(NSSet *)value;
- (void)removeVisualStimuli:(NSSet *)value;

@end

