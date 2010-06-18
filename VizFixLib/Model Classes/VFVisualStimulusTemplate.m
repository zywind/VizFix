// 
//  VFVisualStimulusTemplate.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFVisualStimulusTemplate.h"


@implementation VFVisualStimulusTemplate 

@dynamic imageFilePath;
@dynamic zorder;
@dynamic category;
@dynamic outline;
@dynamic fillColor;
@dynamic strokeColor;
@dynamic ofVisualStimuli;
@dynamic fixationPointAsString;

- (void)awakeFromInsert {
	// The default value of fixationPoint is (100000, 100000), which means that the variable is not set.
	self.fixationPoint = NSMakePoint(1.0e+5f, 1.0e+5f);
}

- (void)awakeFromFetch {
	// When the fixationPoint is still fault (the value is not retrieved from the persistent store), its
	// value is 100000.
	// Note the subtle difference between the implementation here and the implmentation in awakeFromInsert:
	// This implementation does not invoke set method, and so does not set fixationPointAsString.
	fixationPoint = NSMakePoint(1.0e+5f, 1.0e+5f);
}

- (NSPoint)primitiveFixationPoint
{
    return fixationPoint;
}

- (void)setPrimitiveFixationPoint:(NSPoint)aFixationPoint
{
	fixationPoint = aFixationPoint;
}

- (NSPoint)fixationPoint
{
	
    [self willAccessValueForKey:@"fixationPoint"];
	
    NSPoint aLocatinon = fixationPoint;
	
    [self didAccessValueForKey:@"fixationPoint"];
	
    if (aLocatinon.x == 1.0e+5f)
    {
        NSString *fixationPointAsString = [self fixationPointAsString];
		
        if (fixationPointAsString != nil) 
		{
            fixationPoint = NSPointFromString(fixationPointAsString);
        }
    }
	
    return fixationPoint;
}

- (void)setFixationPoint:(NSPoint)aPoint
{
    [self willChangeValueForKey:@"fixationPoint"];
    fixationPoint = aPoint;
    [self didChangeValueForKey:@"fixationPoint"];
	
    NSString *fixationPointAsString = NSStringFromPoint(aPoint);
	[self setValue:fixationPointAsString forKey:@"fixationPointAsString"]; 
}

@end
