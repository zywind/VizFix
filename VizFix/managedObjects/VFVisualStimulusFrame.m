// 
//  VFVisualStimulusFrame.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFVisualStimulusFrame.h"

#import "VFVisualStimulus.h"

@implementation VFVisualStimulusFrame 

@dynamic endTime;
@dynamic startTime;
@dynamic ofVisualStimulus;
@dynamic locationAsString;

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

@end
