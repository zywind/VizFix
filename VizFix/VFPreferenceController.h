//
//  VFPreferenceController.h
//  VizFix
//
//  Created by Yunfeng Zhang on 3/9/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const VFAutoAOISizeKey;
extern NSString * const VFFixationColorKey;

@interface VFPreferenceController : NSWindowController {
	IBOutlet NSTextField *AOISizeTextField;
	IBOutlet NSColorWell *FixationColorWell;
}

@end
