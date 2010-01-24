//
//  VFDTFixationAlg.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFGazeSample.h"
#import "VFFixation.h"

@interface VFDTFixationAlg : NSObject {
	NSUInteger radiusThreshold;
	NSUInteger gazeSampleRate;
}

@property (nonatomic, assign) NSUInteger gazeSampleRate;
@property (nonatomic, assign) NSUInteger radiusThreshold;

- (NSArray *)detectFixation:(NSArray *)gazeArray inMOC:(NSManagedObjectContext *)moc;
- (NSUInteger)thresholdOfNumConsecutiveInvalidSamples;
- (NSUInteger)minNumInFixation;
- (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point;
- (NSArray *)dispersionOfGazes:(NSArray *)gazes;
- (NSPoint)centroidOfGazes:(NSArray *)gazes;
- (NSArray *)timeSortDescriptor;
@end
