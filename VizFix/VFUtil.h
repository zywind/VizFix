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
+ (NSArray *)fetchModelObjectsForName:(NSString *)entityName 
								 from:(NSNumber *)startTime 
								   to:(NSNumber *)endTime 
							  withMOC:(NSManagedObjectContext *)moc;
+ (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point;
@end
