// 
//  VFSession.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFSession.h"

#import "VFVisualStimulusTemplate.h"
#import "VFBlock.h"

@implementation VFSession

@dynamic screenResolutionAsString;
@dynamic screenDimensionAsString;
@dynamic sessionID;
@dynamic experiment;
@dynamic distanceToScreen;
@dynamic subjectID;
@dynamic gazeSampleRate;
@dynamic date;
@dynamic blocks;
@dynamic background;

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

- (BOOL)leaf
{
	return NO;
}

- (NSSet *)children
{
	return self.blocks;
}

- (NSString *)ID
{
	return [NSString stringWithFormat:@"%@ %@", self.subjectID, self.sessionID];
}

- (void)setNilValueForKey:(NSString *)key 
{
	if ([key isEqualToString:@"screenDimension"]) {
		screenDimension = NSMakeSize(0.0f, 0.0f);
    } else if ([key isEqualToString:@"screenResolution"]) {
		screenResolution = NSMakeSize(0.0f, 0.0f);
	} else {
        [super setNilValueForKey:key];
    }
}

@end
