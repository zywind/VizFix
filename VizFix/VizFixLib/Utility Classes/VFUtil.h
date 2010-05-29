//
//  VFUtil.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/30/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VFSession;
@interface VFUtil : NSObject {

}

+ (NSArray *)timeSortDescriptor;
+ (NSArray *)startTimeSortDescriptor;
+ (NSArray*)visualStimuliSortDescriptors;
+ (NSArray *)fetchModelObjectsForName:(NSString *)entityName 
								 from:(NSNumber *)startTime 
								   to:(NSNumber *)endTime 
							  withMOC:(NSManagedObjectContext *)moc;
+ (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point;
+ (VFSession *)fetchSessionWithMOC:(NSManagedObjectContext *)moc;
+ (NSArray *)fetchAllObjectsForName:(NSString *)entityName fromMOC:(NSManagedObjectContext *)moc;
+ (NSPredicate *)predicateForObjectsWithStartTime:(NSNumber *)startTime endTime:(NSNumber *)endTime;
+ (NSBezierPath *)autoAOIAroundCenter:(NSPoint)center withSize:(NSSize)aoiSize;
@end
