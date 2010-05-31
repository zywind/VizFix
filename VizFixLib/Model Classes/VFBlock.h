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

@interface VFBlock :  NSManagedObject  
{
	
}

@property (nonatomic, retain) NSString * ID;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSSet* trials;
@property (nonatomic, retain) VFSession * inSession;
@property (nonatomic, retain) NSSet* conditions;
@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;

@end

@interface VFBlock (CoreDataGeneratedAccessors)
- (void)addTrialsObject:(VFTrial *)value;
- (void)removeTrialsObject:(VFTrial *)value;
- (void)addTrials:(NSSet *)value;
- (void)removeTrials:(NSSet *)value;

- (void)addConditionsObject:(VFCondition *)value;
- (void)removeConditionsObject:(VFCondition *)value;
- (void)addConditions:(NSSet *)value;
- (void)removeConditions:(NSSet *)value;

@end

