//
//  VFDocument.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/13/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFDocument.h"

#import "PrioritySplitViewDelegate.h"
#import "SBCenteringClipView.h"
#import <VizFixLib/VFUtil.h>
#import <VizFixLib/VFDTFixationAlg.h>
#import "VFPreferenceController.h"

@implementation VFDocument

@synthesize currentTime;
@synthesize viewEndTime;
@synthesize viewStartTime;
@synthesize inSummaryMode;
@synthesize minFixationDuration;
@synthesize dispersionThreshold;

#define LEFT_VIEW_INDEX 0
#define LEFT_VIEW_PRIORITY 1
#define LEFT_VIEW_MINIMUM_WIDTH 0
#define RIGHT_VIEW_INDEX 1
#define RIGHT_VIEW_PRIORITY 0
#define RIGHT_VIEW_MINIMUM_WIDTH 100.0

- (id)init 
{
    self = [super init];
    if (self != nil) {
		inSummaryMode = NO;
		playing = NO;
		viewRefreshRate = 30.0;
		playbackSpeedModifiers = [NSArray arrayWithObjects:[NSNumber numberWithDouble:0.1/1.0], 
								  [NSNumber numberWithDouble:1.0/3.0], [NSNumber numberWithDouble:0.5/1.0], 
								  [NSNumber numberWithDouble:1.0/1.0], [NSNumber numberWithDouble:2.0/1.0], nil];
		playbackSpeedLabels = [NSArray arrayWithObjects:@"1/10 x", @"1/3 x", @"1/2 x", @"1 x", @"2 x", nil];
		playbackSpeedModifiersIndex = 2; // Default speed 0.5/1.0.
		step = 1000.0 / viewRefreshRate * [[playbackSpeedModifiers objectAtIndex:playbackSpeedModifiersIndex] doubleValue];
		
		fetchHelper = [[VFFetchHelper alloc] initWithMoc:[self managedObjectContext]];
		
		minFixationDuration = 100;
		dispersionThreshold = 0.7;
	}
    return self;
}

- (NSString *)windowNibName 
{
    return @"VFDocument";
}

- (id)managedObjectModel
{
	static id sharedModel = nil;
    if (sharedModel == nil) {
		NSURL *modelURL = [NSURL fileURLWithPath:@"/Library/Frameworks/VizFixLib.framework/Resources/VFModel.mom"];
        sharedModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] retain];
    }
    return sharedModel;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
	
	[treeController addObserver:self forKeyPath:@"selectionIndexPaths" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"inSummaryMode" options:0 context:NULL];
		
	[layoutView bind:@"inSummaryMode" toObject:self withKeyPath:@"inSummaryMode" options:nil];
	[layoutView bind:@"currentTime" toObject:self withKeyPath:@"currentTime" options:nil];
	layoutView.document = self;
	
	// Retrieve Session.
	session = [fetchHelper session];
	
	// Control the resizing of splitView
	PrioritySplitViewDelegate *splitViewDelegate =
	[[PrioritySplitViewDelegate alloc] init];
	
	[splitViewDelegate
	 setPriority:LEFT_VIEW_PRIORITY
	 forViewAtIndex:LEFT_VIEW_INDEX];
	[splitViewDelegate
	 setMinimumLength:LEFT_VIEW_MINIMUM_WIDTH
	 forViewAtIndex:LEFT_VIEW_INDEX];
	[splitViewDelegate
	 setPriority:RIGHT_VIEW_PRIORITY
	 forViewAtIndex:RIGHT_VIEW_INDEX];
	[splitViewDelegate
	 setMinimumLength:RIGHT_VIEW_MINIMUM_WIDTH
	 forViewAtIndex:RIGHT_VIEW_INDEX];
	
	[splitView setDelegate:splitViewDelegate];
	
	// For centering the view in scrollview
	id docView = [scrollView documentView];
	id newClipView = [[SBCenteringClipView alloc] initWithFrame:[[scrollView contentView] frame]];
	[newClipView setBackgroundColor:[NSColor windowBackgroundColor]];
	[newClipView setDocumentView:docView];
	[scrollView setContentView:(NSClipView *)newClipView];
	
	// Initialize layoutView.
	[layoutView setSession:session];
	[layoutView setDataURL:[self fileURL]];
	
	[playButton setButtonType:NSToggleButton];
	
	speedLabel.stringValue = [playbackSpeedLabels objectAtIndex:playbackSpeedModifiersIndex];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self && [keyPath isEqualToString:@"inSummaryMode"]) {
		if (self.inSummaryMode && playing) {
			[playButton performClick:self];
		}
		
	} else if (object == treeController && [keyPath isEqualToString:@"selectionIndexPaths"]) {
		[self updateTableView];
		[layoutView updateViewContentsFrom:self.viewStartTime to:self.viewEndTime];
	}
}

- (NSError *)willPresentError:(NSError *)inError {
	
    // The error is a Core Data validation error if its domain is
    // NSCocoaErrorDomain and it is between the minimum and maximum
    // for Core Data validation error codes.
	
    if (!([[inError domain] isEqualToString:NSCocoaErrorDomain])) {
        return inError;
    }
	
    NSInteger errorCode = [inError code];
    if ((errorCode < NSValidationErrorMinimum) ||
		(errorCode > NSValidationErrorMaximum)) {
        return inError;
    }
	
    // If there are multiple validation errors, inError is an
    // NSValidationMultipleErrorsError. If it's not, return it
	
    if (errorCode != NSValidationMultipleErrorsError) {
        return inError;
    }
	
    // For an NSValidationMultipleErrorsError, the original errors
    // are in an array in the userInfo dictionary for key NSDetailedErrorsKey
    NSArray *detailedErrors = [[inError userInfo] objectForKey:NSDetailedErrorsKey];
	
    // For this example, only present error messages for up to 3 validation errors at a time.
	
    unsigned numErrors = [detailedErrors count];
    NSMutableString *errorString = [NSMutableString stringWithFormat:@"%u validation errors have occurred", numErrors];
	
    if (numErrors > 3) {
        [errorString appendFormat:@".\nThe first 3 are:\n"];
    }
    else {
        [errorString appendFormat:@":\n"];
    }
    NSUInteger i, displayErrors = numErrors > 3 ? 3 : numErrors;
    for (i = 0; i < displayErrors; i++) {
        [errorString appendFormat:@"%@\n",
		 [[detailedErrors objectAtIndex:i] localizedDescription]];
    }
	
    // Create a new error with the new userInfo
    NSMutableDictionary *newUserInfo = [NSMutableDictionary
										dictionaryWithDictionary:[inError userInfo]];
    [newUserInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
	
    NSError *newError = [NSError errorWithDomain:[inError domain] code:[inError code] userInfo:newUserInfo];
	
    return newError;
}

#pragma mark -
#pragma mark ---------BROWSE DATA---------


- (void)updateTableView
{
	[tableViewController removeObjects:[tableViewController arrangedObjects]];
	
	NSDictionary *emptyLine = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"entry", @"", @"value", nil];

	if ([[treeController selectedObjects] count] != 0) {
		
		NSMutableArray *condDicts = [NSMutableArray array];
		NSMutableArray *statsDicts = [NSMutableArray array];

		NSArray *factorSortDesc = [NSArray arrayWithObject:
								   [[NSSortDescriptor alloc] initWithKey:@"factor" ascending:YES]];
		NSArray *measureSortDesc = [NSArray arrayWithObject:
									[[NSSortDescriptor alloc] initWithKey:@"measure" ascending:YES]];

		VFProcedure *proc = [[treeController selectedObjects] objectAtIndex:0];
		
		self.viewStartTime = [proc.startTime intValue];
		self.viewEndTime = [proc.endTime intValue];
		self.currentTime = self.viewStartTime;	
		
		do {
			
			for (VFCondition *eachCondition in [[proc.conditions allObjects] 
												sortedArrayUsingDescriptors:factorSortDesc]) {
				
				[condDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:eachCondition.factor, 
									  @"entry", eachCondition.level, @"value", nil]];
			}

			for (VFStatistic *eachStat in [[proc.statistics allObjects] 
										   sortedArrayUsingDescriptors:measureSortDesc]) {
				[statsDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:eachStat.measure, 
									  @"entry", eachStat.value, @"value", nil]];
			}
			
			proc = proc.parentProc;
		} while (proc);
		
		if ([condDicts count] != 0) {
			[tableViewController addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Conditions:", @"entry", @"", @"value", nil]];
			[tableViewController addObjects:condDicts];
			[tableViewController addObject:[emptyLine copy]];
		}
		
		if ([statsDicts count] != 0) {
			[tableViewController addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Statistics:", @"entry", @"", @"value", nil]];
			[tableViewController addObjects:statsDicts];		
			[tableViewController addObject:[emptyLine copy]];
		}
	}
	
	[tableViewController addObject:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"Session Info:", @"entry", @"", @"value", nil]];
	[tableViewController addObject:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"Experiment", @"entry", session.experiment, @"value", nil]];

	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle:NSDateFormatterMediumStyle];
	[tableViewController addObject: 
		[NSDictionary dictionaryWithObjectsAndKeys:@"Date", @"entry", 
		 [dateFormat stringFromDate:session.date], @"value", nil]];
	
	[dateFormat setDateStyle:NSDateFormatterNoStyle];
	[dateFormat setTimeStyle:NSDateFormatterMediumStyle];
	[tableViewController addObject: 
	 [NSDictionary dictionaryWithObjectsAndKeys:@"Time", @"entry", 
	  [dateFormat stringFromDate:session.date], @"value", nil]];
	
	[tableViewController addObject:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"Subject", @"entry", session.subjectID, @"value", nil]];
	
	[tableViewController addObject:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"Session", @"entry", session.sessionID, @"value", nil]];
	
	[tableViewController addObject:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"Duration (seconds)", @"entry", 
	  [NSNumber numberWithInt:[session.duration intValue] / 1000], @"value", nil]];
}

#pragma mark -
#pragma mark ---------UI UPDATE---------
- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];
	if (theAction == @selector(toggleShowLabel:)) {
		NSMenuItem *menuItem = (NSMenuItem *)anItem;
		[menuItem setState:layoutView.showLabel];
	} else if (theAction == @selector(toggleShowAutoAOI:)) {
		NSMenuItem *menuItem = (NSMenuItem *)anItem;
		[menuItem setState:layoutView.showAutoAOI];
	} else if (theAction == @selector(toggleShowGazeSample:)) {
		NSMenuItem *menuItem = (NSMenuItem *)anItem;
		[menuItem setState:layoutView.showGazeSample];
	}
	
	return YES;
}

- (IBAction)toggleShowLabel:(id)sender
{
	sender = (NSMenuItem *)sender;
	[sender setState:![sender state]];
	layoutView.showLabel = [sender state];
}

- (IBAction)toggleShowAutoAOI:(id)sender
{
	sender = (NSMenuItem *)sender;
	[sender setState:![sender state]];
	layoutView.showAutoAOI = [sender state];
}

- (IBAction)toggleShowGazeSample:(id)sender
{
	sender = (NSMenuItem *)sender;
	[sender setState:![sender state]];
	layoutView.showGazeSample = [sender state];
}

#pragma mark -
#pragma mark ---------PLAYBACK CONTROL---------
- (IBAction)togglePlayState:(id)sender
{
	playing = !playing;
	if (playing) {
		playTimer = [NSTimer timerWithTimeInterval:(1.0/viewRefreshRate)
											target:self 
										  selector:@selector(increaseCurrentTime:) 
										  userInfo:nil 
										   repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:playTimer
									 forMode:NSDefaultRunLoopMode];
	} else {
		[playTimer invalidate];
	}
}

- (IBAction)speedUp:(id)sender
{
	if (playbackSpeedModifiersIndex < [playbackSpeedModifiers count] - 1) {
		playbackSpeedModifiersIndex++;
		speedLabel.stringValue = [playbackSpeedLabels objectAtIndex:playbackSpeedModifiersIndex];
		step = 1000.0 / viewRefreshRate * [[playbackSpeedModifiers objectAtIndex:playbackSpeedModifiersIndex] doubleValue];
	}
}

- (IBAction)slowDown:(id)sender
{
	if (playbackSpeedModifiersIndex > 0) {
		playbackSpeedModifiersIndex--;
		speedLabel.stringValue = [playbackSpeedLabels objectAtIndex:playbackSpeedModifiersIndex];
		step = 1000.0 / viewRefreshRate * [[playbackSpeedModifiers objectAtIndex:playbackSpeedModifiersIndex] doubleValue];
	}	
}

- (IBAction)stepForward:(id)sender
{
	[layoutView	stepForward];
}

- (IBAction)stepBackward:(id)sender
{
	[layoutView stepBackward];
}

- (void)increaseCurrentTime:(NSTimer*)theTimer
{
	if (self.currentTime <= self.viewEndTime - step)
		self.currentTime += step;
	else {
		[playButton performClick:self];
		self.currentTime = self.viewStartTime;
	}
}

#pragma mark -
#pragma mark ---------DETECT FIXATIONS---------
- (IBAction)detectFixations:(id)sender
{
	[NSApp beginSheet:detectFixationPanel
	   modalForWindow:[[[self windowControllers] objectAtIndex:0] window] 
		modalDelegate:self 
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) 
		  contextInfo:nil];
}

- (IBAction)cancelDetection: (id)sender
{
    [NSApp endSheet:detectFixationPanel returnCode:NSCancelButton];
}

- (IBAction)doDetect: (id)sender
{
	[NSApp endSheet:detectFixationPanel returnCode:NSOKButton];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[self doDetectAndInsertFixations];
		[layoutView updateViewContentsFrom:self.viewStartTime to:self.viewEndTime];
    }
    [sheet orderOut:self];
}

- (void)doDetectAndInsertFixations
{
	NSManagedObjectContext *moc = [session managedObjectContext];
	NSArray *fixationArray = [fetchHelper fetchModelObjectsForName:@"Fixation" 
															  from:[NSNumber numberWithDouble:viewStartTime]
																to:[NSNumber numberWithDouble:viewEndTime]];
	
	for (VFFixation *eachFixation in fixationArray) {
		[moc deleteObject:eachFixation];
	}
	fixationArray = nil;
	
	NSArray *gazes = [fetchHelper fetchModelObjectsForName:@"GazeSample" 
													  from:[NSNumber numberWithDouble:viewStartTime]
														to:[NSNumber numberWithDouble:viewEndTime]];
	
	[VFDTFixationAlg detectFixation:gazes 
			withDispersionThreshold:self.dispersionThreshold 
			 andMinFixationDuration:self.minFixationDuration];
}

- (NSArray *)startTimeSortDescriptor
{
	return [VFUtil startTimeSortDescriptor];
}
					  

@end
