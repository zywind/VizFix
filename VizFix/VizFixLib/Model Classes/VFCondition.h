//
//  VFCondition.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFTrial;
@class VFBlock;

@interface VFCondition :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * factor;
@property (nonatomic, retain) NSString * level;
@property (nonatomic, retain) NSSet* ofTrial;
@property (nonatomic, retain) NSSet* ofBlock;

@end


@interface VFCondition (CoreDataGeneratedAccessors)
- (void)addOfTrialObject:(VFTrial *)value;
- (void)removeOfTrialObject:(VFTrial *)value;
- (void)addOfTrial:(NSSet *)value;
- (void)removeOfTrial:(NSSet *)value;

- (void)addOfBlockObject:(VFBlock *)value;
- (void)removeOfBlockObject:(VFBlock *)value;
- (void)addOfBlock:(NSSet *)value;
- (void)removeOfBlock:(NSSet *)value;

@end

