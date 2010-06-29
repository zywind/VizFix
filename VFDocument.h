//
//  VFDocument.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/13/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VFView.h"
#import <VizFixLib/VizFixLib.h>

@interface VFDocument : NSPersistentDocument {
	VFFetchHelper *fetchHelper;
	VFSession *session;
	
	// Playback control
	double viewRefreshRate;
	NSArray *playbackSpeedModifiers;
	NSArray *playbackSpeedLabels;
	int playbackSpeedModifiersIndex;
	double viewStartTime;
	double viewEndTime;
	double currentTime;
	NSTimer *playTimer;	
	BOOL playing;
	BOOL inSummaryMode;
	
	int minFixationDuration;
	double dispersionThreshold;
	
	// UI elements
	IBOutlet NSSplitView *splitView;
	IBOutlet NSScrollView *scrollView;
	IBOutlet NSButton *playButton;
	IBOutlet VFView	*layoutView;
	IBOutlet NSTextField *speedLabel;
	IBOutlet NSComboBox *detectingGroupBox;
	
	// UI elements data sources.
	IBOutlet NSTreeController *treeController;
	IBOutlet NSArrayController *tableViewController;
	IBOutlet NSPanel *detectFixationPanel;
	
	double step;
}

@property (nonatomic, assign) double currentTime;
@property (nonatomic, assign) double viewEndTime;
@property (nonatomic, assign) double viewStartTime;
@property (nonatomic, assign) BOOL inSummaryMode;

@property (nonatomic, assign) int minFixationDuration;
@property (nonatomic, assign) double dispersionThreshold;

// Playback control.
- (IBAction)togglePlayState:(id)sender;
- (IBAction)speedUp:(id)sender;
- (IBAction)slowDown:(id)sender;
- (IBAction)stepForward:(id)sender;
- (IBAction)stepBackward:(id)sender;
- (void)increaseCurrentTime:(NSTimer*)theTimer;
// Browse data.
- (void)updateTableView;

// Menu actions.
- (IBAction)toggleShowLabel:(id)sender;
- (IBAction)toggleShowAutoAOI:(id)sender;
- (IBAction)toggleShowGazeSample:(id)sender;
- (IBAction)detectFixations:(id)sender;
- (IBAction)captureVisualization:(id)sender;
- (void)doDetectAndInsertFixations;

- (NSArray *)startTimeSortDescriptor;

- (IBAction)cancelDetection: (id)sender;
- (IBAction)doDetect: (id)sender;

@end
