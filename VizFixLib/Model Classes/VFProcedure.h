//
//  VFTrial.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "VFCondition.h"
#import "VFStatistic.h"

@interface VFProcedure :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSString * ID;
@property (nonatomic, retain) VFProcedure * parentProc;
@property (nonatomic, retain) NSSet* subProcs;

@property (nonatomic, retain) NSSet* conditions;
@property (nonatomic, retain) NSSet* statistics;

@property (nonatomic, readonly) BOOL leaf;

@end


@interface VFProcedure (CoreDataGeneratedAccessors)
- (void)addSubProcsObject:(VFProcedure *)value;
- (void)removeSubProcsObject:(VFProcedure *)value;
- (void)addSubProcs:(NSSet *)value;
- (void)removeSubProcs:(NSSet *)value;

- (void)addConditionsObject:(VFCondition *)value;
- (void)removeConditionsObject:(VFCondition *)value;
- (void)addConditions:(NSSet *)value;
- (void)removeConditions:(NSSet *)value;

- (void)addStatisticsObject:(VFStatistic *)value;
- (void)removeStatisticsObject:(VFStatistic *)value;
- (void)addStatistics:(NSSet *)value;
- (void)removeStatistics:(NSSet *)value;

@end

