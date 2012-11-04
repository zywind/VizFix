/********************************************************************
 File:  VFView.h
 
 Created:  1/15/10
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
#import <VizFixLib/VizFixLib.h>

@class VFDocument;

@interface VFView : NSView {
	VFDocument *__weak document;
	VFFetchHelper *fetchHelper;
	
	IBOutlet NSTextField *keyLabel;
	NSArray *gazesArray;
	NSArray *fixationsArray;
	NSArray *visualStimuliArray;
	NSArray *keyEventsArray;
	VFSession *session;
	NSURL *dataURL;
	
	NSMutableDictionary *imageCacheDict;
	
	double viewScale;
	BOOL showLabel;
	BOOL showDistanceGuide;
	BOOL showGazeSample;
	BOOL showScanpath;	
	BOOL inSummaryMode;
	double currentTime;
	double viewStartTime;
	double viewEndTime;
	float distanceGuideSizeDOV;
	
	NSUInteger selectedGroupType; // 2 for block, 3 for trial, 4 for subtrial
	
	VFVisualAngleConverter *DOVConverter;
	
	NSPredicate *playbackPredicateForTimePeriod;
	NSPredicate *playbackPredicateForTimeStamp;

}

@property BOOL showLabel;
@property BOOL showDistanceGuide;
@property BOOL showGazeSample;
@property BOOL showScanpath;
@property BOOL inSummaryMode;
@property BOOL flippedView;
@property double viewScale;
@property double currentTime;
@property double viewEndTime;
@property double viewStartTime;
@property (strong) NSURL *dataURL;
@property (weak) VFDocument *document;

- (void)setSession:(VFSession *)session;
- (IBAction)changeViewScale:(id)sender;

// Draw helper methods.
- (void)drawFrame:(VFVisualStimulusFrame *)frame;
- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate withAlpha:(double)alpha;
- (void)drawGazes;
- (void)showKeyEvents;
- (void)drawFixations;
- (void)drawFixation:(VFFixation *)currentFixation withColor:(NSColor *)color;
- (void)updateViewContents;

- (void)stepForward;
- (void)stepBackward;
@end
