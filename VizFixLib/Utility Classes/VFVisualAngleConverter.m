//
//  VFVisualAngleConverter.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/28/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

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
