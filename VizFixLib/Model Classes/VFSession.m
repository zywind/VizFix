/********************************************************************
 File:   VFSession.m
 
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

#import "VFSession.h"

@implementation VFSession

@dynamic screenResolutionAsString;
@dynamic screenDimensionAsString;
@dynamic sessionID;
@dynamic experiment;
@dynamic distanceToScreen;
@dynamic subjectID;
@dynamic gazeSampleRate;
@dynamic date;
@dynamic backgroundColor;
@dynamic duration;

- (NSSize)primitiveScreenResolution
{
    return screenResolution;
}

- (void)setPrimitiveScreenResolution:(NSSize)aSize
{
	screenResolution = aSize;
}

- (NSSize)primitiveScreenDimension
{
    return screenDimension;
}

- (void)setPrimitiveScreenDimension:(NSSize)aSize
{
	screenDimension = aSize;
}

- (NSSize)screenResolution
{
	
    [self willAccessValueForKey:@"screenResolution"];
	
    NSSize aSize = screenResolution;
	
    [self didAccessValueForKey:@"screenResolution"];
	
    if (aSize.width == 0 && aSize.height == 0) // TODO: check if this assumption works.
    {
        NSString *screenResolutionAsString = [self screenResolutionAsString];
		
        if (screenResolutionAsString != nil) 
		{
            aSize = NSSizeFromString(screenResolutionAsString);
        }
    }
	
    return aSize;
}

- (void)setScreenResolution:(NSSize)aSize
{
    [self willChangeValueForKey:@"screenResolution"];
    screenResolution = aSize;
    [self didChangeValueForKey:@"screenResolution"];
	
    NSString *screenResolutionAsString = NSStringFromSize(aSize);
	[self setValue:screenResolutionAsString forKey:@"screenResolutionAsString"]; 
}

- (NSSize)screenDimension
{
	
    [self willAccessValueForKey:@"screenDimension"];
	
    NSSize aSize = screenDimension;
	
    [self didAccessValueForKey:@"screenDimension"];
	
    if (aSize.width == 0 && aSize.height == 0) // TODO: check if this assumption works.
    {
        NSString *screenDimensionAsString = [self screenDimensionAsString];
		
        if (screenDimensionAsString != nil) 
		{
            aSize = NSSizeFromString(screenDimensionAsString);
        }
    }
	
    return aSize;
}

- (void)setScreenDimension:(NSSize)aSize
{
    [self willChangeValueForKey:@"screenDimension"];
    screenDimension = aSize;
    [self didChangeValueForKey:@"screenDimension"];
	
    NSString *screenDimensionAsString = NSStringFromSize(aSize);
	[self setValue:screenDimensionAsString forKey:@"screenDimensionAsString"]; 
}

@end