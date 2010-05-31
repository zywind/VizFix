//
//  VFAppDelegate.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class VFPreferenceController;

@interface VFAppDelegate : NSObject {
	VFPreferenceController *prefController;
}

- (IBAction)showPreferencePanel:(id)sender;
@end
