//
//  VFCondition.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFProcedure;
@class VFBlock;

@interface VFCondition :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * factor;
@property (nonatomic, retain) NSString * level;
@property (nonatomic, retain) NSSet* ofProcs;

@end


@interface VFCondition (CoreDataGeneratedAccessors)
- (void)addOfProcsObject:(VFProcedure *)value;
- (void)removeOfProcsObject:(VFProcedure *)value;
- (void)addOfProcs:(NSSet *)value;
- (void)removeOfProcs:(NSSet *)value;
@end

