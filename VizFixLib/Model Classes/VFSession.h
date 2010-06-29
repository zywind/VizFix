//
//  VFSession.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <AppKit/AppKit.h>
#import "VFProcedure.h"

/**
	Stores information regarding the session.
 */
@interface VFSession :  NSManagedObject  
{
	NSSize screenResolution;
	NSSize screenDimension;
}

/**
 ￼	Experiment name.
 */
@property (nonatomic, retain) NSString * experiment;
/**
 ￼	Subject ID.
 */
@property (nonatomic, retain) NSString * subjectID;
/**
 ￼	Session ID.
 */
@property (nonatomic, retain) NSString * sessionID;
/**
 ￼	Session date and time.
 */
@property (nonatomic, retain) NSDate * date;
/**
 ￼	Experiment display background color.
 */
@property (nonatomic, retain) NSColor * backgroundColor;
/**
	￼Screen resolution in pixels, width X height.
 */
@property (nonatomic, assign) NSSize screenResolution;
@property (nonatomic, assign) NSSize primitiveScreenResolution;
/**
 ￼	Screen dimension in mm, width X height.
 */
@property (nonatomic, assign) NSSize screenDimension;
@property (nonatomic, assign) NSSize primitiveScreenDimension;
@property (nonatomic, retain) NSString * screenResolutionAsString;
@property (nonatomic, retain) NSString * screenDimensionAsString;
/**
 ￼	Subject's eye-to-screen distance, in mm.
 */
@property (nonatomic, retain) NSNumber * distanceToScreen;
/**
 ￼	Eye tracker's sampling rate.
 */
@property (nonatomic, retain) NSNumber * gazeSampleRate;
/**
 ￼	Session's duration.
 */
@property (nonatomic, retain) NSNumber * duration;

@end