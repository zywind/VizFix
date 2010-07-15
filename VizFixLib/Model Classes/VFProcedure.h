/********************************************************************
 File:   VFProcedure.h
 
 Created:  1/22/10
 Modified: 7/15/10
 
 Author: Yunfeng Zhang
 Cognitive Modeling and Eye Tracking Lab
 CIS Department
 University of Oregon
 
 Funded by the Office of Naval Research & National Science Foundation.
 Primary Investigator: Anthony Hornof.
 
 Copyright (c) 2010 by the University of Oregon.
 ALL RIGHTS RESERVED.
 
 Permission to use, copy, and distribute this software in
 its entirety for non-commercial purposes and without fee,
 is hereby granted, provided that the above copyright notice
 and this permission notice appear in all copies and their
 documentation.
 
 Software developers, consultants, or anyone else who wishes
 to use all or part of the software or its documentation for
 commercial purposes should contact the Technology Transfer
 Office at the University of Oregon to arrange a commercial
 license agreement.
 
 This software is provided "as is" without expressed or
 implied warranty of any kind.
 ********************************************************************/

#import <CoreData/CoreData.h>

#import "VFCondition.h"
#import "VFStatistic.h"

/**
	￼Stores information about a Procedure.
 */
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

@end


@interface VFProcedure (CoreDataGeneratedAccessors)
- (void)addSubProcsObject:(VFProcedure *)value;
- (void)removeSubProcsObject:(VFProcedure *)value;
- (void)addSubProcs:(NSSet *)value;
- (void)removeSubProcs:(NSSet *)value;

/**
 ￼Add a condition object.
 @param value ￼The condition being added.
 */
- (void)addConditionsObject:(VFCondition *)value;
- (void)removeConditionsObject:(VFCondition *)value;
- (void)addConditions:(NSSet *)value;
- (void)removeConditions:(NSSet *)value;

- (void)addStatisticsObject:(VFStatistic *)value;
- (void)removeStatisticsObject:(VFStatistic *)value;
- (void)addStatistics:(NSSet *)value;
- (void)removeStatistics:(NSSet *)value;

@end

