//
//  VFDocument.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/13/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFDocument.h"

@implementation VFDocument

@synthesize currentTime;
@synthesize viewEndTime;
@synthesize viewStartTime;
@synthesize inSummaryMode;

#define LEFT_VIEW_INDEX 0
#define LEFT_VIEW_PRIORITY 1
#define LEFT_VIEW_MINIMUM_WIDTH 200.0
#define RIGHT_VIEW_INDEX 1
#define RIGHT_VIEW_PRIORITY 0
#define RIGHT_VIEW_MINIMUM_WIDTH 200.0

- (id)init 
{
    self = [super init];
    if (self != nil) {
		inSummaryMode = NO;
		playing = NO;
		viewRefreshRate = 30.0;
		playbackSpeedModifiers = [NSArray arrayWithObjects:[NSNumber numberWithDouble:0.1/1.0], 
								  [NSNumber numberWithDouble:0.3/1.0], [NSNumber numberWithDouble:0.5/1.0], 
								  [NSNumber numberWithDouble:1.0/1.0], [NSNumber numberWithDouble:2.0/1.0], nil];
		playbackSpeedModifiersIndex = 2; // Default speed 0.5/1.0.
    }
    return self;
}

- (NSString *)windowNibName 
{
    return @"VFDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
	
	[visualStimuliController addObserver:layoutView forKeyPath:@"filterPredicate" options:NSKeyValueObservingOptionNew context:NULL];
	[treeController addObserver:self forKeyPath:@"selectionIndexPaths" options:NSKeyValueObservingOptionNew context:NULL];
	
	[self addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"inSummaryMode" options:NSKeyValueObservingOptionNew context:NULL];
	[layoutView bind:@"inSummaryMode" toObject:self withKeyPath:@"inSummaryMode" options:NULL];

	// Retrieve Session.
	NSError *fetchError = nil;
	NSArray *fetchResults;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session"
											  inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	
	fetchResults = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&fetchError];
	if ((fetchResults != nil) && ([fetchResults count] == 1) && (fetchError == nil)) {
		session = [fetchResults objectAtIndex:0];
	} else {
		[self presentError:fetchError];
	}
	
	[sessionController setContent:session];
	
	// Control the resizing of splitView
	splitViewDelegate =
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
	
	// draw the layoutView.
	NSUInteger indexArr [] = {0, 0, 0, 0};
	[treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndexes:indexArr length:4]];
	[treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
	
	[playButton setButtonType:NSToggleButton];
	

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self && [keyPath isEqualToString:@"currentTime"]) {
		[self updateViewContents];
	} else if (object == self && [keyPath isEqualToString:@"inSummaryMode"]) {
		if (self.inSummaryMode && playing) {
			[playButton performClick:self];
		}
		
		[self updateViewContents];
	} else if (object == treeController && [keyPath isEqualToString:@"selectionIndexPaths"]) {
		[self changeSelectedGroup];
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
- (void)updateViewContents
{
	NSPredicate *predicateForTimePeriod, *timePredicate;
	if (!self.inSummaryMode) {
		predicateForTimePeriod = [NSPredicate predicateWithFormat:
								  @"(startTime <= %f AND endTime >= %f)", 
								  currentTime, currentTime];
		timePredicate = [NSPredicate predicateWithFormat:@"time <= %f AND time >= %f", 
						 currentTime, currentTime - 100];
	} else {
		predicateForTimePeriod = [NSPredicate predicateWithFormat:
								  @"(startTime <= %f AND endTime >= %f) OR (startTime >= %f AND startTime <= %f)", 
								  viewStartTime, viewStartTime, viewStartTime, viewEndTime];
		timePredicate = [NSPredicate predicateWithFormat:@"time <= %f AND time >= %f", 
						 viewEndTime, viewStartTime];
	}
	
	[visualStimuliController setFilterPredicate:predicateForTimePeriod];
	[visualStimulusFramesController setFilterPredicate:predicateForTimePeriod];
	[fixationController setFilterPredicate:predicateForTimePeriod];
	[gazeSampleController setFilterPredicate:timePredicate];
}

- (void)changeSelectedGroup
{
	if ([[treeController selectionIndexPaths] count] == 0)
		return;
	
	VFBlock *selectedBlock = nil;
	VFTrial *selectedTrial = nil;
	VFSubTrial *selectedSubTrial = nil;
	NSDictionary *tempDict;

	[tableViewController removeObjects:[tableViewController arrangedObjects]];
	
	NSIndexPath *indexPath = [[treeController selectionIndexPaths] objectAtIndex:0];
	if ([indexPath length] == 1) {
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
		return;
	}
	if ([indexPath length] >= 2) {
		selectedBlock = (VFBlock *)[[[[session blocks] allObjects] 
									 sortedArrayUsingDescriptors:[self startTimeSortDescriptor]] 
									objectAtIndex:[indexPath indexAtPosition:1]];
		[blockController setSelectionIndex:[indexPath indexAtPosition:1]];
		
		tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Conditions:", @"entry", @"", @"value", nil];
		[tableViewController addObject:tempDict];
		for (VFCondition *eachCondition in selectedBlock.conditions) {
			tempDict = [NSDictionary dictionaryWithObjectsAndKeys:eachCondition.factor, 
					@"entry", eachCondition.level, @"value", nil];
			[tableViewController addObject:tempDict];
		}
	}
	if ([indexPath length] >= 3) {
		selectedTrial = [[[[selectedBlock trials] allObjects] 
						 sortedArrayUsingDescriptors:[self startTimeSortDescriptor]]
						 objectAtIndex:[indexPath indexAtPosition:2]];
				
		for (VFCondition *eachCondition in selectedTrial.conditions) {
			tempDict = [NSDictionary dictionaryWithObjectsAndKeys:eachCondition.factor, 
					@"entry", eachCondition.level, @"value", nil];
			[tableViewController addObject:tempDict];
		}
		
		tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"entry", @"", @"value", nil];
		[tableViewController addObject:tempDict];
		
		tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Responses:", @"entry", @"", @"value", nil];
		[tableViewController addObject:tempDict];
		for (VFResponse *eachResponse in selectedTrial.responses) {
			tempDict = [NSDictionary dictionaryWithObjectsAndKeys:eachResponse.measure, 
						@"entry", eachResponse.value, @"value", nil];
			[tableViewController addObject:tempDict];
			tempDict = [NSDictionary dictionaryWithObjectsAndKeys:@"error", 
						@"entry", eachResponse.error, @"value", nil];
			[tableViewController addObject:tempDict];
		}
	}
	if ([indexPath length] == 4) {
		selectedSubTrial = [[[[selectedTrial subTrials] allObjects]
							sortedArrayUsingDescriptors:[self startTimeSortDescriptor]] 
							objectAtIndex:[indexPath indexAtPosition:3]];
	}
	
	if (selectedSubTrial != nil) {
		self.viewStartTime = [selectedSubTrial.startTime intValue];
		self.viewEndTime = [selectedSubTrial.endTime intValue];
	} else if (selectedTrial != nil) {
		self.viewStartTime = [selectedTrial.startTime intValue];
		self.viewEndTime = [selectedTrial.endTime intValue];
	} else if (selectedBlock != nil) {
		self.viewStartTime = [selectedBlock.startTime intValue];
		self.viewEndTime = [selectedBlock.endTime intValue];
	}
	self.currentTime = self.viewStartTime;
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
	[layoutView setShowLabel:[sender state]];
}

- (IBAction)toggleShowAutoAOI:(id)sender
{
	sender = (NSMenuItem *)sender;
	[sender setState:![sender state]];
	[layoutView setShowAutoAOI:[sender state]];
}

- (IBAction)toggleShowGazeSample:(id)sender
{
	sender = (NSMenuItem *)sender;
	[sender setState:![sender state]];
	[layoutView setShowGazeSample:[sender state]];
}

#pragma mark -
#pragma mark ---------PLAYBACK CONTROL---------
- (IBAction)togglePlayState:(id)sender
{
	playing = !playing;
	if (playing) {
		NSRunLoop *runloop = [NSRunLoop currentRunLoop];
		playTimer = [NSTimer timerWithTimeInterval:(1.0/viewRefreshRate)
											target:self 
										  selector:@selector(increaseCurrentTime:) 
										  userInfo:nil 
										   repeats:YES];
		[runloop addTimer:playTimer forMode:NSDefaultRunLoopMode];
	} else {
		[playTimer invalidate];
	}
}

- (IBAction)speedUp:(id)sender
{
	if (playbackSpeedModifiersIndex < [playbackSpeedModifiers count] - 1) {
		playbackSpeedModifiersIndex++;
	}
}

- (IBAction)slowDown:(id)sender
{
	if (playbackSpeedModifiersIndex > 0) {
		playbackSpeedModifiersIndex--;
	}
}

- (void)increaseCurrentTime:(NSTimer*)theTimer
{
	double step = 1000.0 / viewRefreshRate * [[playbackSpeedModifiers objectAtIndex:playbackSpeedModifiersIndex] doubleValue];
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
    }
}

- (void)doDetectAndInsertFixations
{
	NSManagedObjectContext *importFixationsMoc = [self managedObjectContext];
	
	// Delete old fixations
	NSEntityDescription *fixatinoEntityDescription = [NSEntityDescription
													  entityForName:@"Fixation" inManagedObjectContext:importFixationsMoc];
	NSFetchRequest *fixationRequest = [[NSFetchRequest alloc] init];
	[fixationRequest setEntity:fixatinoEntityDescription];
	
	NSError *error;
	NSArray *fixationArray = [importFixationsMoc executeFetchRequest:fixationRequest error:&error];
	
	for (VFFixation *eachFixation in fixationArray) {
		[importFixationsMoc deleteObject:eachFixation];
	}
	
	// Delete block-fixations relationship.
	for (VFBlock *eachBlock in session.blocks) {
		eachBlock.fixations = nil;
	}
	fixationArray = nil;
	
	// Retrieve gazes
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"GazeSample" inManagedObjectContext:importFixationsMoc];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	NSArray *gazeArray = [importFixationsMoc executeFetchRequest:request error:&error];
	if (gazeArray == nil)
	{
		NSLog(@"Fetch gaze samples failed.\n%@", [error localizedDescription]);
		return;
	}
	
	VFDTFixationAlg *fixationDetectionAlg = [[VFDTFixationAlg alloc] init];
	fixationDetectionAlg.gazeSampleRate = 120;
	fixationDetectionAlg.radiusThreshold = 30; // TODO:
	
	NSMutableArray *fixations = [NSMutableArray arrayWithArray:
								 [fixationDetectionAlg detectFixation:gazeArray inMOC:importFixationsMoc]];
	gazeArray = nil;
	
	for (VFBlock *eachBlock in session.blocks) {
		NSMutableArray *tempFixations = [NSMutableArray arrayWithArray:fixations];
		NSPredicate * predicateForTimePeriod = [NSPredicate predicateWithFormat:
												@"(startTime <= %@ AND endTime >= %@) OR (startTime >= %@ AND startTime <= %@)", 
												eachBlock.startTime, eachBlock.startTime, eachBlock.startTime, eachBlock.endTime];
		[tempFixations filterUsingPredicate:predicateForTimePeriod];
		[eachBlock addFixations:[NSSet setWithArray:tempFixations]];
	}
	fixations = nil;
}

#pragma mark -
#pragma mark ---------SORT DESCRIPTORS---------
//	This returns the sort descriptor (in an array) used
//	for sorting all objects that exists for a time period.
- (NSArray *)startTimeSortDescriptor
{
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
	return [NSArray arrayWithObject:sort];
}

//	This returns the sort descriptor (in an array) used
//	for sorting all objects that used time.
- (NSArray *)timeSortDescriptor
{
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
	return [NSArray arrayWithObject:sort];
}

- (NSArray*)visualStimuliSortDescriptors
{
	NSSortDescriptor *zorderSort = [[NSSortDescriptor alloc] initWithKey:@"template.zorder" ascending:YES];
	NSSortDescriptor *timeSort = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
	return [NSArray arrayWithObjects:zorderSort, timeSort, nil];
}
@end
