/********************************************************************
 File:   VFSession.h
 
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
@property (nonatomic, strong) NSString * experiment;
/**
 ￼	Subject ID.
 */
@property (nonatomic, strong) NSString * subjectID;
/**
 ￼	Session ID.
 */
@property (nonatomic, strong) NSString * sessionID;
/**
 ￼	Session date and time.
 */
@property (nonatomic, strong) NSDate * date;
/**
 ￼	Experiment display background color.
 */
@property (nonatomic, strong) NSColor * backgroundColor;
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
@property (nonatomic, strong) NSString * screenResolutionAsString;
@property (nonatomic, strong) NSString * screenDimensionAsString;
/**
 ￼	Subject's eye-to-screen distance, in mm.
 */
@property (nonatomic, strong) NSNumber * distanceToScreen;
/**
 ￼	Eye tracker's sampling rate.
 */
@property (nonatomic, strong) NSNumber * gazeSampleRate;
/**
 ￼	Session's duration.
 */
@property (nonatomic, strong) NSNumber * duration;

@end