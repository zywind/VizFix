//
//  VFVisualStimulus.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFVisualStimulusTemplate;

/*! Visual stimulus.
 */
@interface VFVisualStimulus :  NSManagedObject  
{
}

@property (nonatomic, retain) VFVisualStimulusTemplate * template;
@property (nonatomic, retain) NSSet* frames;
@property (nonatomic, retain) NSNumber * endTime;

/*! Start time.
 */
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * ID;

@end


@interface VFVisualStimulus (CoreDataGeneratedAccessors)
- (void)addFramesObject:(NSManagedObject *)value;
- (void)removeFramesObject:(NSManagedObject *)value;
- (void)addFrames:(NSSet *)value;
- (void)removeFrames:(NSSet *)value;

@end

