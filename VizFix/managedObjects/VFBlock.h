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

@interface VFBlock :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * ID;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSSet* keyboardEvents;
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

