//
//  VFUtil.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/30/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFSession.h"
#import "VFCondition.h"
#import "VFResponse.h"
#import "VFView.h"
#import "VFSession.h"
#import "VFBlock.h"
#import "VFTrial.h"
#import "VFSubTrial.h"
#import "VFFixation.h"
#import "VFVisualStimulus.h"

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
@end
