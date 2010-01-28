//
//  VFTrial.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFBlock;
@class VFSubTrial;
@class VFVisualStimulus;
@class VFAuditoryStimulus;
@class VFCondition;
@class VFResponse;

@interface VFTrial :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSString * ID;
@property (nonatomic, retain) VFBlock * inBlock;
@property (nonatomic, retain) NSSet* subTrials;
@property (nonatomic, retain) NSSet* targetVisualStimuli;
@property (nonatomic, retain) NSSet* targetAuditoryStimuli;
@property (nonatomic, retain) NSSet* conditions;
@property (nonatomic, retain) NSSet* responses;
@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;


@end


@interface VFTrial (CoreDataGeneratedAccessors)
- (void)addSubTrialsObject:(VFSubTrial *)value;
- (void)removeSubTrialsObject:(VFSubTrial *)value;
- (void)addSubTrials:(NSSet *)value;
- (void)removeSubTrials:(NSSet *)value;

- (void)addTargetVisualStimuliObject:(VFVisualStimulus *)value;
- (void)removeTargetVisualStimuliObject:(VFVisualStimulus *)value;
- (void)addTargetVisualStimuli:(NSSet *)value;
- (void)removeTargetVisualStimuli:(NSSet *)value;

- (void)addTargetAuditoryStimuliObject:(VFAuditoryStimulus *)value;
- (void)removeTargetAuditoryStimuliObject:(VFAuditoryStimulus *)value;
- (void)addTargetAuditoryStimuli:(NSSet *)value;
- (void)removeTargetAuditoryStimuli:(NSSet *)value;

- (void)addConditionsObject:(VFCondition *)value;
- (void)removeConditionsObject:(VFCondition *)value;
- (void)addConditions:(NSSet *)value;
- (void)removeConditions:(NSSet *)value;

- (void)addResponsesObject:(VFResponse *)value;
- (void)removeResponsesObject:(VFResponse *)value;
- (void)addResponses:(NSSet *)value;
- (void)removeResponses:(NSSet *)value;

@end
