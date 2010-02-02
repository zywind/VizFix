//
//  VFVisualAngleConverter.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/28/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFUtil.h"

@class VFUtil;
@class VFSession;

@interface VFVisualAngleConverter : NSObject {
	NSSize screenResolution;
	NSSize screenDimension;
	NSUInteger distanceToScreen; 
}

/*!
 In pixels.
 */
@property (assign) NSSize screenResolution;
/*!
 In mm.
 */
@property (assign) NSSize screenDimension;
/*!
 In mm.
 */
@property (assign) NSUInteger distanceToScreen;

- (id)initWithDistanceToScreen:(NSUInteger)distance 
			  screenResolution:(NSSize)resolution 
			   screenDimension:(NSSize)dimension;
- (id)initWithMOC:(NSManagedObjectContext *)moc;

- (double)horizontalPixelsFromVisualAngles:(double)DOV;
- (double)horizontalVisualAnglesFromPixels:(double)pixels;
- (double)verticalPixelsFromVisualAngles:(double)DOV;
- (double)verticalVisualAnglesFromPixels:(double)pixels;

@end
