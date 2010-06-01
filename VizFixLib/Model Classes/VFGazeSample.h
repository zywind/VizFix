//
//  VFGazeSample.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 VFGazeSample is used to store the raw gaze sample information in the vizfixsql file. 
 It has several properties that need to be assigned: #location, #valid, #time.  Other properties are optional.
 */
@interface VFGazeSample :  NSManagedObject  
{
	NSPoint location;
}

/**
 The gaze sample's location.
 */
@property (nonatomic, assign) NSPoint location;
/**
 A Boolean value is wrapped in the NSNumber object to indicate whether the gaze sample is valid.
 */
@property (nonatomic, retain) NSNumber * valid;
/**
 The gaze sample's recording time, in ms.
 */
@property (nonatomic, retain) NSNumber * time;
/**
 Optional.
 */
@property (nonatomic, retain) NSNumber * pupilDiameter;
/**
 Optional.
 */
@property (nonatomic, retain) NSNumber * focusRange;
/**
 Optional.
 */
@property (nonatomic, retain) NSNumber * xEyeOffset;
/**
 Optional.
 */
@property (nonatomic, retain) NSNumber * yEyeOffset;

@property (nonatomic, retain) NSString * locationAsString;
@property (nonatomic, assign) NSPoint primitiveLocation;

@end