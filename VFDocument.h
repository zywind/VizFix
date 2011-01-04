/********************************************************************
 File:  VFDocument.h
 
 Created:  1/13/10
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
- (IBAction)toggleShowDistanceGuide:(id)sender;
- (IBAction)toggleShowGazeSample:(id)sender;
- (IBAction)toggleShowScanpath:(id)sender;
- (IBAction)detectFixations:(id)sender;
- (IBAction)captureVisualization:(id)sender;
- (void)doDetectAndInsertFixations;

- (NSArray *)startTimeSortDescriptor;

- (IBAction)cancelDetection: (id)sender;
- (IBAction)doDetect: (id)sender;

@end
