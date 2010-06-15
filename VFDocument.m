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

@implementation VFDocument

@synthesize currentTime;
@synthesize viewEndTime;
@synthesize viewStartTime;
@synthesize inSummaryMode;

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
	session = [VFUtil fetchSessionWithMOC:[self managedObjectContext]];
	
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
	
	NSDictionary *tempDict;

	if ([[treeController selectedObjects] count] != 0) {
	
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
				
				tempDict = [NSDictionary dictionaryWithObjectsAndKeys:eachCondition.factor, 
							@"entry", eachCondition.level, @"value", nil];
				[tableViewController addObject:tempDict];
			}

			for (VFStatistic *eachStat in [[proc.statistics allObjects] 
										   sortedArrayUsingDescriptors:measureSortDesc]) {
				tempDict = [NSDictionary dictionaryWithObjectsAndKeys:eachStat.measure, 
							@"entry", eachStat.value, @"value", nil];
				[tableViewController addObject:tempDict];			
			}
			
			proc = proc.parentProc;
		} while (proc);
	}
	
	tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Experiment", @"entry", session.experiment, @"value", nil];
	[tableViewController addObject:tempDict];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle:NSDateFormatterMediumStyle];
	tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Date", @"entry", 
				[dateFormat stringFromDate:session.date], @"value", nil];
	[tableViewController addObject:tempDict];
	[dateFormat setDateStyle:NSDateFormatterNoStyle];
	[dateFormat setTimeStyle:NSDateFormatterMediumStyle];
	tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Time", @"entry", 
				[dateFormat stringFromDate:session.date], @"value", nil];
	[tableViewController addObject:tempDict];
	tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Subject", @"entry", session.subjectID, @"value", nil];
	[tableViewController addObject:tempDict];
	tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Session", @"entry", session.sessionID, @"value", nil];
	[tableViewController addObject:tempDict];
	tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Duration (seconds)", @"entry", [NSNumber numberWithInt:[session.duration intValue] / 1000], @"value", nil];
	[tableViewController addObject:tempDict];
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
	// Show alert panel.
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Continue"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"This will delete your old fixations. Continue?"];
	[alert setInformativeText:@"Detect fixations will delete your old fixations. Continue?"];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	[alert beginSheetModalForWindow:[[[self windowControllers] objectAtIndex:0] window] 
					  modalDelegate:self 
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
						contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode
		contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
		[self doDetectAndInsertFixations];
		[layoutView updateViewContentsFrom:self.viewStartTime to:self.viewEndTime];
    }
}

- (void)doDetectAndInsertFixations
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSArray *fixationArray = [VFUtil fetchAllObjectsForName:@"Fixation" fromMOC:moc];
	
	for (VFFixation *eachFixation in fixationArray) {
		[moc deleteObject:eachFixation];
	}
	
	fixationArray = nil;
		
	VFDTFixationAlg *fixationDetectionAlg = [[VFDTFixationAlg alloc] init];

	[fixationDetectionAlg detectAllFixationsInMOC:moc withRadiusThresholdInDOV:0.7];
}

- (NSArray *)startTimeSortDescriptor
{
	return [VFUtil startTimeSortDescriptor];
}

@end
