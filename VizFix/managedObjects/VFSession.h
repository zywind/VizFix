//
//  VFSession.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <AppKit/AppKit.h>

@class VFVisualStimulusTemplate;
@class VFBlock;

@interface VFSession :  NSManagedObject  
{
}

@property (nonatomic, retain) VFVisualStimulusTemplate * background;
@property (nonatomic, retain) NSNumber * screenResolutionHeight;
@property (nonatomic, retain) NSNumber * screenDimensionHeight;
@property (nonatomic, retain) NSString * sessionID;
@property (nonatomic, retain) NSString * experiment;
@property (nonatomic, retain) NSNumber * distanceToScreen;
@property (nonatomic, retain) NSNumber * screenDimensionWidth;
@property (nonatomic, retain) NSString * subjectID;
@property (nonatomic, retain) NSNumber * gazeSampleRate;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * screenResolutionWidth;
@property (nonatomic, retain) NSSet* blocks;
@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;
@property (nonatomic, readonly) NSString* ID;

@end


@interface VFSession (CoreDataGeneratedAccessors)
- (void)addBlocksObject:(VFBlock *)value;
- (void)removeBlocksObject:(VFBlock *)value;
- (void)addBlocks:(NSSet *)value;
- (void)removeBlocks:(NSSet *)value;

@end

