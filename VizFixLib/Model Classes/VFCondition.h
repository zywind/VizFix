//
//  VFCondition.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFProcedure;

/**
 Stores statistics of a procedure.
 */
@interface VFCondition :  NSManagedObject  
{
}

/**
	Factor name.￼
 */
@property (nonatomic, retain) NSString * factor;
/**
	The factor level of this condition.￼
 */
@property (nonatomic, retain) NSString * level;
@property (nonatomic, retain) NSSet* ofProcs;

@end


@interface VFCondition (CoreDataGeneratedAccessors)

/**
	I usually use VFProcedure::addConditionsObject instead.
	@param value ￼The procedure being added.
 */
- (void)addOfProcsObject:(VFProcedure *)value;
- (void)removeOfProcsObject:(VFProcedure *)value;
- (void)addOfProcs:(NSSet *)value;
- (void)removeOfProcs:(NSSet *)value;
@end

