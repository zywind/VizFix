//
//  VFDocument.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/13/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFView.h"
#import "VFSession.h"
#import "VFBlock.h"
#import "VFTrial.h"
#import "VFSubTrial.h"
#import "PrioritySplitViewDelegate.h"
#import "VFDTFixationAlg.h"
#import "VFCondition.h"
#import "VFResponse.h"
#import "SBCenteringClipView.h"

@class PrioritySplitViewDelegate;

@interface VFDocument : NSPersistentDocument {
	IBOutlet NSObjectController *sessionController;
	IBOutlet NSArrayController *blockController;
	IBOutlet NSArrayController *trialController;
	IBOutlet NSArrayController *subTrialController;
	VFSession *session;
	
	// Playback control
	double viewRefreshRate;
	NSArray *playbackSpeedModifiers;
	int playbackSpeedModifiersIndex;
	double viewStartTime;
	double viewEndTime;
	double currentTime;
	NSTimer *playTimer;	
	BOOL playing;
	BOOL inSummaryMode;
	
	// UI elements
	IBOutlet NSSplitView *splitView;
	PrioritySplitViewDelegate *splitViewDelegate;	
	IBOutlet NSScrollView *scrollView;
	IBOutlet NSButton *playButton;
	IBOutlet VFView	*layoutView;
	// UI elements data sources.
	IBOutlet NSTreeController *treeController;
	IBOutlet NSArrayController *tableViewController;
}

@property (nonatomic, assign) double currentTime;
@property (nonatomic, assign) double viewEndTime;
@property (nonatomic, assign) double viewStartTime;
@property (nonatomic, assign) BOOL inSummaryMode;

// Sort descriptors.
- (NSArray *)startTimeSortDescriptor;
- (NSArray *)visualStimuliSortDescriptors;
- (NSArray *)timeSortDescriptor;

// Playback control.
- (IBAction)togglePlayState:(id)sender;
- (IBAction)speedUp:(id)sender;
- (IBAction)slowDown:(id)sender;
- (void)increaseCurrentTime:(NSTimer*)theTimer;
// Browse data.
- (void)updateTableView;

// Menu actions.
- (IBAction)toggleShowLabel:(id)sender;
- (IBAction)toggleShowAutoAOI:(id)sender;
- (IBAction)toggleShowGazeSample:(id)sender;
- (IBAction)detectFixations:(id)sender;
- (void)doDetectAndInsertFixations;
@end
