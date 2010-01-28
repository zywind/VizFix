//
//  SBCenteringClipView.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/27/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//
// Taken from http://www.bergdesign.com/developer/index_files/88a764e343ce7190c4372d1425b3b6a3-0.html

#import <Cocoa/Cocoa.h>


@interface SBCenteringClipView : NSClipView {
	NSPoint _lookingAt; // the proportion up and across the view, not coordinates.
}

-(void)centerDocument;

@end
