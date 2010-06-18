//
//  VFVisualStimulusTemplate.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <AppKit/AppKit.h>
#import "VFVisualStimulus.h"

@interface VFVisualStimulusTemplate :  NSManagedObject  
{
	NSPoint fixationPoint;
}

@property (nonatomic, retain) NSString * imageFilePath;
@property (nonatomic, retain) NSNumber * zorder;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSBezierPath * outline;
@property (nonatomic, retain) NSColor * fillColor;
@property (nonatomic, retain) NSColor * strokeColor;
@property (nonatomic, retain) NSSet* ofVisualStimuli;
@property (nonatomic, assign) NSPoint fixationPoint;
@property (nonatomic, assign) NSPoint primitiveFixationPoint;
@property (nonatomic, retain) NSString * fixationPointAsString;

@end

@interface VFVisualStimulusTemplate (CoreDataGeneratedAccessors)
- (void)addOfVisualStimuliObject:(VFVisualStimulus *)value;
- (void)removeOfVisualStimuliObject:(VFVisualStimulus *)value;
- (void)addOfVisualStimuli:(NSSet *)value;
- (void)removeOfVisualStimuli:(NSSet *)value;
@end



