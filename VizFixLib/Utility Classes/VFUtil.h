//
//  VFUtil.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/30/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VFUtil : NSObject {

}

+ (NSArray *)timeSortDescriptor;
+ (NSArray *)startTimeSortDescriptor;
+ (NSArray*)visualStimuliSortDescriptors;
+ (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point;
+ (NSPredicate *)predicateForObjectsWithStartTime:(NSNumber *)startTime endTime:(NSNumber *)endTime;
+ (NSBezierPath *)autoAOIAroundPoint:(NSPoint)center withSize:(NSSize)aoiSize;
@end
