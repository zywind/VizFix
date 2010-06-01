//
//  VFView.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/15/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VizFixLib/VFMangedObjects.h>
#import <VizFixLib/VFVisualAngleConverter.h>

@class VFDocument;

@interface VFView : NSView {
	VFDocument *document;
	
	IBOutlet NSArrayController *blockController;
	IBOutlet NSArrayController *trialController;
	IBOutlet NSArrayController *subTrialController;
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
	BOOL showAutoAOI;
	BOOL showGazeSample;
	BOOL inSummaryMode;
	double currentTime;
	float autoAOISizeDOV;
	
	NSUInteger selectedGroupType; // 2 for block, 3 for trial, 4 for subtrial
	
	VFVisualAngleConverter *DOVConverter;
	
	NSPredicate *playbackPredicateForTimePeriod;
	NSPredicate *playbackPredicateForTimeStamp;

	
	IBOutlet NSTreeController *treeController;
}

@property BOOL showLabel;
@property BOOL showAutoAOI;
@property BOOL showGazeSample;
@property BOOL inSummaryMode;
@property double viewScale;
@property double currentTime;
@property (retain) NSURL *dataURL;
@property VFDocument *document;

- (void)setSession:(VFSession *)session;
- (IBAction)changeViewScale:(id)sender;

// Draw helper methods.
- (void)drawFrame:(VFVisualStimulusFrame *)frame;
- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate;
- (void)drawGazes;
- (void)showKeyEvents;
- (void)drawFixations;
- (void)drawFixation:(VFFixation *)currentFixation withColor:(NSColor *)color;
- (void)updateViewContentsFrom:(double)viewStartTime to:(double)viewEndTime;

- (void)stepForward;
- (void)stepBackward;
@end
