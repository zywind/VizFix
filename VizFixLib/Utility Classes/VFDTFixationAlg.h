//
//  VFDTFixationAlg.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VFDTFixationAlg : NSObject {
	
}

+ (void)detectFixation:(NSArray *)gazeArray withDispersionThreshold:(double)DTInDov andMinFixationDuration:(double)minFixationDuration;
+ (NSPoint)centroidOfGazes:(NSArray *)gazes;
+ (float)dispersionOfGazes:(NSArray *)gazes;

@end
