/********************************************************************
 File:   VFGazeSample.h
 
 Created:  1/22/10
 Modified: 7/15/10
 
 Author: Yunfeng Zhang
 Cognitive Modeling and Eye Tracking Lab
 CIS Department
 University of Oregon
 
 Funded by the Office of Naval Research & National Science Foundation.
 Primary Investigator: Anthony Hornof.
 
 Copyright (c) 2010 by the University of Oregon.
 ALL RIGHTS RESERVED.
 
 Permission to use, copy, and distribute this software in
 its entirety for non-commercial purposes and without fee,
 is hereby granted, provided that the above copyright notice
 and this permission notice appear in all copies and their
 documentation.
 
 Software developers, consultants, or anyone else who wishes
 to use all or part of the software or its documentation for
 commercial purposes should contact the Technology Transfer
 Office at the University of Oregon to arrange a commercial
 license agreement.
 
 This software is provided "as is" without expressed or
 implied warranty of any kind.
 ********************************************************************/

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