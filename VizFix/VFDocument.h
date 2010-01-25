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

@class PrioritySplitViewDelegate;

@interface VFDocument : NSPersistentDocument {
	IBOutlet NSArrayController *visualStimuliController;
	IBOutlet NSArrayController *visualStimulusFramesController;
	IBOutlet NSArrayController *gazeSampleController;
	IBOutlet NSArrayController *fixationController;
	IBOutlet NSObjectController *sessionController;
	IBOutlet NSArrayController *blockController;
	
	IBOutlet NSTreeController *treeController;
	IBOutlet NSArrayController *tableViewController;
	IBOutlet NSObjectController *fileURLController;

	IBOutlet NSSplitView *splitView;
	PrioritySplitViewDelegate *splitViewDelegate;
	IBOutlet NSButton *playButton;
	
	VFSession *session;
	
	IBOutlet VFView	*layoutView;
	double viewRefreshRate;
	NSArray *playbackSpeedModifiers;
	int playbackSpeedModifiersIndex;
	double viewStartTime;
	double viewEndTime;
	double currentTime;
		
	NSTimer *playTimer;
	
	BOOL playing;
	BOOL inSummaryMode;
}

@property (nonatomic, assign) double currentTime;
@property (nonatomic, assign) double viewEndTime;
@property (nonatomic, assign) double viewStartTime;
@property (nonatomic, assign) BOOL inSummaryMode;

- (NSArray *)startTimeSortDescriptor;
- (NSArray *)visualStimuliSortDescriptor;
- (NSArray *)timeSortDescriptor;

- (void)updateViewContents;

- (IBAction)togglePlayState:(id)sender;
- (IBAction)speedUp:(id)sender;
- (IBAction)slowDown:(id)sender;
- (IBAction)toggleShowLabel:(id)sender;

- (void)increaseCurrentTime:(NSTimer*)theTimer;
- (IBAction)toggleSummaryMode:(id)sender;
- (void)changeSelectedGroup;
- (IBAction)detectFixations:(id)sender;
@end
