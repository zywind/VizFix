/********************************************************************
 File:   VFVisualStimulusTemplate.m
 
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
