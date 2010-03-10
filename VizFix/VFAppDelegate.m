//
//  VFAppDelegate.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFAppDelegate.h"
#import "VFPreferenceController.h"

@implementation VFAppDelegate

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setObject:[NSNumber numberWithFloat:2.0f] forKey:VFAutoAOISizeKey];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (IBAction)showPreferencePanel:(id)sender
{
	if (!prefController) {
		prefController = [[VFPreferenceController alloc] init];
	}
	[prefController showWindow:self];
}

@end
