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
	NSSize screenResolution;
	NSSize screenDimension;
}

@property (nonatomic, assign) NSSize screenResolution;
@property (nonatomic, assign) NSSize primitiveScreenResolution;
@property (nonatomic, assign) NSSize screenDimension;
@property (nonatomic, assign) NSSize primitiveScreenDimension;
@property (nonatomic, retain) NSString * screenResolutionAsString;
@property (nonatomic, retain) NSString * screenDimensionAsString;

@property (nonatomic, retain) VFVisualStimulusTemplate * background;
@property (nonatomic, retain) NSString * sessionID;
@property (nonatomic, retain) NSString * experiment;
@property (nonatomic, retain) NSNumber * distanceToScreen;
@property (nonatomic, retain) NSString * subjectID;
@property (nonatomic, retain) NSNumber * gazeSampleRate;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSSet* blocks;
@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;
@property (nonatomic, readonly) NSString* ID;
@property (nonatomic, retain) NSNumber * duration;

@end


@interface VFSession (CoreDataGeneratedAccessors)
- (void)addBlocksObject:(VFBlock *)value;
- (void)removeBlocksObject:(VFBlock *)value;
- (void)addBlocks:(NSSet *)value;
- (void)removeBlocks:(NSSet *)value;

@end

