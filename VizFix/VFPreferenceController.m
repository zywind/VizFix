//
//  VFPreferenceController.m
//  VizFix
//
//  Created by Yunfeng Zhang on 3/9/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFPreferenceController.h"

NSString * const VFAutoAOISizeKey = @"AutoAOISize";

@implementation VFPreferenceController

- (id)init
{
	if (![super initWithWindowNibName:@"Preferences"])
		return nil;
	
	return self;
}

@end
