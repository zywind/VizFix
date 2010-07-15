/********************************************************************
 File:   VFFixation.m
 
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

#import "VFFixation.h"


@implementation VFFixation 

@dynamic startTime;
@dynamic endTime;
@dynamic locationAsString;
@dynamic fixatedAOI;

- (NSPoint)primitiveLocation
{
    return location;
}

- (void)setPrimitiveLocation:(NSPoint)aLocation
{
	location = aLocation;
}

- (NSPoint)location
{
	
    [self willAccessValueForKey:@"location"];
	
    NSPoint aLocatinon = location;
	
    [self didAccessValueForKey:@"location"];
	
    if (aLocatinon.x == 0 && aLocatinon.y == 0) // TODO: check if this assumption works.
    {
        NSString *locationAsString = [self locationAsString];
		
        if (locationAsString != nil) 
		{
            location = NSPointFromString(locationAsString);
        }
    }
	
    return location;
}

- (void)setLocation:(NSPoint)aPoint
{
    [self willChangeValueForKey:@"location"];
    location = aPoint;
    [self didChangeValueForKey:@"location"];
	
    NSString *locationAsString = NSStringFromPoint(aPoint);
	[self setValue:locationAsString forKey:@"locationAsString"]; 
}

- (void)setNilValueForKey:(NSString *)key 
{
	if ([key isEqualToString:@"location"]) {
		location = NSMakePoint(0.0f, 0.0f);
    }
    else {
        [super setNilValueForKey:key];
    }
}

- (void)registerOnAOI:(NSString *)aoiID
{
	if (self.fixatedAOI == nil) {
		self.fixatedAOI = aoiID;
	} else {
		self.fixatedAOI = [self.fixatedAOI stringByAppendingFormat:@"&%@", aoiID];
	}
}

@end
