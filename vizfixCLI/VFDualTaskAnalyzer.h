//
//  VFDualTaskAnalyzer.h
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 1/31/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "VFUtil.h"

@interface VFDualTaskAnalyzer : NSObject {
	NSManagedObjectContext *managedObjectContext;
	VFVisualStimulus *targetBlip;
	NSArray *blipsOfCurrentWave;
	NSBezierPath *trackingAOI;
	NSBezierPath *radarAOI;
}

@property (retain) NSManagedObjectContext * managedObjectContext;
- (void)analyze:(NSURL *)storeFileURL;
- (NSString *)findFixatedAOIForFixations:(VFFixation *)fixation;
@end
