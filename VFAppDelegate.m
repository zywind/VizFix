/********************************************************************
 File:  VFAppDelegate.m
 
 Created:  1/18/10
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

#import "VFAppDelegate.h"
#import "VFPreferenceController.h"

@implementation VFAppDelegate

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setObject:[NSNumber numberWithFloat:2.0f] forKey:VFDistanceGuideSizeKey];
	
	NSData *theData=[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedHue:0.8 
																				saturation:1.0 
																				brightness:1.0 
																					 alpha:1.0]];
	[defaultValues setObject:theData forKey:VFFixationColorKey];
    
    NSData *grayColorData = [NSArchiver archivedDataWithRootObject:[NSColor grayColor]];
    [defaultValues setObject:grayColorData forKey:VFUncorrectedFixationColorKey];
    [defaultValues setObject:grayColorData forKey:VFDistanceGuideColorKey];
	
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
