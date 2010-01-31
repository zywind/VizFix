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
#import "VFUtil.h"

@interface VFDTFixationAlg : NSObject {
	NSUInteger radiusThreshold;
	NSUInteger gazeSampleRate;
}

@property (nonatomic, assign) NSUInteger gazeSampleRate;
@property (nonatomic, assign) NSUInteger radiusThreshold;

- (void)detectFixation:(NSArray *)gazeArray inMOC:(NSManagedObjectContext *)moc;
- (NSUInteger)thresholdOfNumConsecutiveInvalidSamples;
- (NSUInteger)minNumInFixation;
- (NSArray *)dispersionOfGazes:(NSArray *)gazes;
- (NSPoint)centroidOfGazes:(NSArray *)gazes;
@end
