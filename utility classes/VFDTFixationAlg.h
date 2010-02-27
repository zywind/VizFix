//
//  VFDTFixationAlg.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VFDTFixationAlg : NSObject {
	double radiusThreshold;
	double gazeSampleRate;
}

- (void)detectAllFixationsInMOC:(NSManagedObjectContext *)moc withRadiusThresholdInDOV:(double)aRadius;
- (void)detectFixation:(NSArray *)gazeArray;
- (NSUInteger)thresholdOfNumConsecutiveInvalidSamples;
- (NSUInteger)minNumInFixation;
- (float)dispersionOfGazes:(NSArray *)gazes;
- (NSPoint)centroidOfGazes:(NSArray *)gazes;
@end
