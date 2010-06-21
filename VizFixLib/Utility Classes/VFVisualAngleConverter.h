//
//  VFVisualAngleConverter.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/28/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VFVisualAngleConverter : NSObject {
	NSSize screenResolution;
	NSSize screenDimension;
	int distanceToScreen; 
}

- (id)initWithMOC:(NSManagedObjectContext *)moc;

- (double)pixelsFromVisualAngles:(double)DOV;
- (double)visualAnglesFromPixels:(double)pixels;

@end
