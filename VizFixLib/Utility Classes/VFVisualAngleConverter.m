//
//  VFVisualAngleConverter.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/28/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFVisualAngleConverter.h"

#import "VFSession.h"
#import "VFUtil.h"

@implementation VFVisualAngleConverter

@synthesize screenResolution;
@synthesize screenDimension;
@synthesize distanceToScreen;

#define RADIANS(degrees) (degrees * M_PI / 180)
#define DEGREES(radians) (radians * 180 / M_PI)

- (id)initWithDistanceToScreen:(NSUInteger)distance 
			  screenResolution:(NSSize)resolution 
			   screenDimension:(NSSize)dimension
{
	self = [super init];
    if (self != nil) {
		self.distanceToScreen = distance;
		self.screenResolution = resolution;
		self.screenDimension = dimension;
    }
    return self;
}

- (id)initWithMOC:(NSManagedObjectContext *)moc
{
	VFSession *session = [VFUtil fetchSessionWithMOC:moc];
	return [self initWithDistanceToScreen:[session.distanceToScreen intValue]
						 screenResolution:session.screenResolution 
						  screenDimension:session.screenDimension];
}

- (double)horizontalPixelsFromVisualAngles:(double)DOV
{
	return tan(RADIANS(DOV/2))*2*distanceToScreen*screenResolution.width/screenDimension.width;
}

- (double)horizontalVisualAnglesFromPixels:(double)pixels
{
	return DEGREES(atan(((pixels/2)/(distanceToScreen*screenResolution.width/screenDimension.width))))*2;
}

- (double)verticalPixelsFromVisualAngles:(double)DOV
{
	return tan(RADIANS(DOV/2))*2*distanceToScreen*screenResolution.height/screenDimension.height;
}

- (double)verticalVisualAnglesFromPixels:(double)pixels
{
	return DEGREES(atan(((pixels/2)/(distanceToScreen*screenResolution.height/screenDimension.height))))*2;
}

@end
