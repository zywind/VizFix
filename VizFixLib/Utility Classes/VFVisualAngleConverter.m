/********************************************************************
 File:   VFVisualAngleConverter.m
 
 Created:  1/28/10
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

#import "VFVisualAngleConverter.h"

#import "VFSession.h"
#import "VFFetchHelper.h"

@implementation VFVisualAngleConverter

#define RADIANS(degrees) (degrees * M_PI / 180)
#define DEGREES(radians) (radians * 180 / M_PI)

- (id)initWithMOC:(NSManagedObjectContext *)moc
{
	self = [super init];
    if (self != nil) {
		VFSession *session = [[[VFFetchHelper alloc] initWithMOC:moc] session];
		
		distanceToScreen = [session.distanceToScreen intValue];
		screenResolution = session.screenResolution;
		screenDimension = session.screenDimension;
    }
    return self;
}

- (double)pixelsFromVisualAngles:(double)DOV
{
	return tan(RADIANS(DOV/2))*2*distanceToScreen*screenResolution.width/screenDimension.width;
}

- (double)visualAnglesFromPixels:(double)pixels
{
	return DEGREES(atan(((pixels/2)/(distanceToScreen*screenResolution.width/screenDimension.width))))*2;
}

@end
