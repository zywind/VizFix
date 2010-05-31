// 
//  VFGazeSample.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFGazeSample.h"


@implementation VFGazeSample 

/*!
 Returns an NSNumber wrapped Boolean value that indicates whether the gaze sample is valid.
 */
@dynamic valid;
/*!
 Optional.
 */
@dynamic pupilDiameter;
/*!
 Optional.
 */
@dynamic yEyeOffset;
/*!
 Optional.
 */
@dynamic focusRange;
/*!
 Returns the gaze sample's recording time, in ms.
 */
@dynamic time;
/*!
 Optional.
 */
@dynamic xEyeOffset;
/**
 Used internally. Use #location instead.
 @see location
 */
@dynamic locationAsString;
/**
 Used internally. Use #location instead.
 @see location
 */
- (NSPoint)primitiveLocation
{
    return location;
}
/**
 Used internally. Use #location instead.
 @see location
 */
- (void)setPrimitiveLocation:(NSPoint)aLocation
{
	location = aLocation;
}

/**
 Returns an NSPoint object that indicates the gaze sample's location.
 */
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
/**
 Sets the gaze sample's location.
 */
- (void)setLocation:(NSPoint)aPoint
{
    [self willChangeValueForKey:@"location"];
    location = aPoint;
    [self didChangeValueForKey:@"location"];
	
    NSString *locationAsString = NSStringFromPoint(aPoint);
	[self setValue:locationAsString forKey:@"locationAsString"]; 
}
/**
 Used internally. Sets the gaze sample's location to (0, 0).
 */
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
