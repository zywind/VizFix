/********************************************************************
 File:  VFView.m
 
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

#import "VFView.h"
#import "VFPreferenceController.h"
#import "VFDocument.h"

@implementation VFView

@synthesize showLabel;
@synthesize showAutoAOI;
@synthesize dataURL;
@synthesize viewScale;
@synthesize showGazeSample;
@synthesize inSummaryMode;
@synthesize currentTime;
@synthesize viewStartTime;
@synthesize viewEndTime;
@synthesize document;

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
    if (self != nil) {
		imageCacheDict = [NSMutableDictionary dictionaryWithCapacity:10];
		viewScale = 100.0 / 100.0;
		showLabel = YES;
		showGazeSample = YES;
		showAutoAOI = NO;
		[self addObserver:self forKeyPath:@"showLabel" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"showAutoAOI" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"showGazeSample" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"viewScale" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"inSummaryMode" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:NULL];
	}
    return self;
}

- (void)setSession:(VFSession *)aSession
{
	session = aSession;
	DOVConverter = [[VFVisualAngleConverter alloc] initWithMOC:[aSession managedObjectContext]];
	[self setFrameSize:session.screenResolution];
	
	fetchHelper = [[VFFetchHelper alloc] initWithMOC:[aSession managedObjectContext]];
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self && [keyPath isEqualToString:@"currentTime"]) {
		playbackPredicateForTimePeriod = [NSPredicate predicateWithFormat:
										  @"(startTime <= %f AND endTime >= %f)", 
										  currentTime, currentTime];
		playbackPredicateForTimeStamp = [NSPredicate predicateWithFormat:
										 @"(time <= %f AND time >= %f)", 
										 currentTime + 100, currentTime];
	}
	[self setNeedsDisplay:YES];
}

- (void)updateViewContents
{
	if (session == nil)
		return;
	
	NSNumber *startTime = [NSNumber numberWithDouble:viewStartTime];
	NSNumber *endTime = [NSNumber numberWithDouble:viewEndTime];
	if (showGazeSample) {
		gazesArray = [fetchHelper fetchModelObjectsForName:@"GazeSample" 
												 from:startTime 
												   to:endTime];
	} else {
		gazesArray = nil;
	}
	visualStimuliArray = [fetchHelper fetchModelObjectsForName:@"VisualStimulus" 
													 from:startTime 
													   to:endTime];
	fixationsArray = [fetchHelper fetchModelObjectsForName:@"Fixation" 
											   from:startTime 
												 to:endTime];
	keyEventsArray = [fetchHelper fetchModelObjectsForName:@"KeyboardEvent" 
												 from:startTime
												   to:endTime];

	[self setNeedsDisplay:YES];
}

- (void)stepForward
{
	NSArray *followingFixations = [fixationsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"startTime > %f", currentTime]];
	if ([followingFixations count] != 0) {
		self.currentTime = [((VFFixation *)[followingFixations objectAtIndex:0]).startTime intValue];
		// The binding is not bidirectional!! I wish there is a better solution.
		document.currentTime = self.currentTime;
	}
}

- (void)stepBackward
{
	NSArray *previousFixations = [fixationsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"startTime < %f", currentTime]];
	if ([previousFixations count] != 0) {
		self.currentTime = [((VFFixation *)[previousFixations lastObject]).startTime intValue];
		document.currentTime = self.currentTime;
	}
}


- (void)drawRect:(NSRect)rect
{
	// Save the previous graphics state
	[NSGraphicsContext saveGraphicsState];
	
	autoAOISizeDOV = [[NSUserDefaults standardUserDefaults] floatForKey:VFAutoAOISizeKey];
	
	NSAffineTransform* xform = [NSAffineTransform transform];
	[xform scaleXBy:viewScale yBy:viewScale];
	[xform concat];
	// Draw background.
	[session.backgroundColor drawSwatchInRect:rect];
	
	// Draw screen objects.
	for (VFVisualStimulus *vs in visualStimuliArray)
	{
		NSSet *frames = vs.frames;

		if (!inSummaryMode) {
			VFVisualStimulusFrame *aFrame = [[frames filteredSetUsingPredicate:playbackPredicateForTimePeriod] anyObject];
			if (aFrame != nil)
				[self drawFrame:aFrame];
		} else {
			NSPredicate *predicate = [VFUtil predicateForObjectsWithStartTime:[NSNumber numberWithDouble:viewStartTime]
																	  endTime:[NSNumber numberWithDouble:viewEndTime]];
			NSArray *vsFrames = [[[frames filteredSetUsingPredicate:predicate] allObjects]
								 sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];			
			
			VFVisualStimulusFrame *lastDrawnFrame;
			for (int i = 0; i < [vsFrames count]; i++) {				
				VFVisualStimulusFrame *thisFrame = [vsFrames objectAtIndex:i];
				if (i == 0 || i == [vsFrames count] - 1 || 
					([VFUtil distanceBetweenThisPoint:thisFrame.location andThatPoint:lastDrawnFrame.location] > 16)){
					[self drawFrame:thisFrame];
					lastDrawnFrame = thisFrame;
				}
			}
		}
	}
	
	if (showGazeSample) {
		[self drawGazes];
	}
	
	// Draw fixations
	[self drawFixations];
	
	if (!inSummaryMode) {
		// Show keyboad events
		[self showKeyEvents];
	}
	
	//	Restore the previous graphics state
	//	saved at the beginning of this method
	[NSGraphicsContext restoreGraphicsState];	
}

#pragma mark -
#pragma mark ---------DRAW HELPER METHODS---------
- (void)drawFrame:(VFVisualStimulusFrame *)frame
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	// Transform the coordinate system to the origin of the ScreenOjbect
	[transform translateXBy:frame.location.x yBy:frame.location.y];	
	[transform concat];
	
	VFVisualStimulus *theStimulus = frame.ofVisualStimulus;
	
	double alpha;
	if (inSummaryMode) {
		alpha = pow(([frame.endTime doubleValue] - viewStartTime) 
				/ (viewEndTime - viewStartTime), 0.7);
	} else {
		alpha = 1.0;
	}
	
	[self drawVisualStimulusTemplate:theStimulus.template withAlpha:alpha];
	// Depends on the label font size.
	if (showLabel) {
		[theStimulus.label drawAtPoint:NSMakePoint(0.0f, 0.0f)
		 withAttributes:[NSDictionary dictionaryWithObject:[NSColor whiteColor] 
													forKey:NSForegroundColorAttributeName]];
	}
	
	[transform invert];
	[transform concat];
}

- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate withAlpha:(double)alpha
{
	if (visualStimulusTemplate.fillColor != nil) {
		[visualStimulusTemplate.fillColor setFill];
		[visualStimulusTemplate.outline fill];
	} 
	
	if (visualStimulusTemplate.imageFilePath != nil) {
		NSString *filePath = [[[dataURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:visualStimulusTemplate.imageFilePath];
		NSURL *imageURL = [NSURL fileURLWithPath:filePath];
		
		NSImage *stimulusImage = [imageCacheDict valueForKey:visualStimulusTemplate.imageFilePath];
		if (stimulusImage == nil) {
			stimulusImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
			// Cache loaded images.
			[imageCacheDict setObject:stimulusImage forKey:visualStimulusTemplate.imageFilePath];
			
			if (stimulusImage == nil) {
				NSLog(@"Image file %@ does not exist.", [imageURL path]);
				return;
			}
		}
		
		NSAffineTransform* xform = [NSAffineTransform transform];
		[xform translateXBy:0.0 yBy:stimulusImage.size.height];
		[xform scaleXBy:1.0 yBy:-1.0];
		[xform concat];
		
		[stimulusImage drawAtPoint:NSMakePoint(0.0f, 0.0f) 
						  fromRect:NSZeroRect 
						 operation:NSCompositeSourceOver
						  fraction:alpha];
		
		
		[xform invert];
		[xform concat];
	}
	
	if (visualStimulusTemplate.strokeColor != nil) {
		[visualStimulusTemplate.strokeColor setStroke];
		[visualStimulusTemplate.outline stroke];
	} 
	
	// If it's drawing background, there's no need to draw auto-AOI.
	if (showAutoAOI && ![visualStimulusTemplate.category isEqualToString:@"background"] 
		&& (visualStimulusTemplate.fixationPoint.x != 1.0e+5f)) {
		NSSize autoAOISize = NSMakeSize([DOVConverter pixelsFromVisualAngles:autoAOISizeDOV], 
										[DOVConverter pixelsFromVisualAngles:autoAOISizeDOV]);
		NSBezierPath *foveaZonePath = [VFUtil autoAOIAroundPoint:visualStimulusTemplate.fixationPoint withSize:autoAOISize];
		
		[[NSColor grayColor] set];
		[foveaZonePath stroke];
	}
}

- (void)drawGazes 
{
	NSArray *gazesToDraw;
	
	if (!inSummaryMode)
		gazesToDraw = [gazesArray filteredArrayUsingPredicate:playbackPredicateForTimeStamp];
	else
		gazesToDraw = gazesArray;

	int i=0;
	for (VFGazeSample *eachGaze in gazesToDraw)
	{
		// TEH I should add conditions so that samples outside
		// the session screen resolution do not draw.
		if([[eachGaze valueForKey:@"valid"] boolValue])
		{
			// Increase the brightness and decrease saturation as the samples progress
			[[NSColor colorWithCalibratedHue:0.5 
								  saturation:(1.0 - ((i / (float)[gazesToDraw count]) / 2.0)) 
								  brightness:(0.5 + ((i / (float)[gazesToDraw count]) / 2.0))
									   alpha:1.0] setFill];
		} else {
			[[NSColor blackColor] setFill];
		}
		NSRect aRect = NSMakeRect(eachGaze.location.x, eachGaze.location.y, 2.0, 2.0);
		NSRectFill(aRect);
		
		i++;
	}
}

- (void)showKeyEvents 
{
	NSArray *tempKeys = [keyEventsArray filteredArrayUsingPredicate:playbackPredicateForTimeStamp];
	
	if ([tempKeys count] > 0) {
		VFKeyboardEvent *key = [tempKeys objectAtIndex:0];
		keyLabel.stringValue = key.key;
	} else {
		keyLabel.stringValue = @"";
	}
}

- (void)drawFixations
{
	NSColor *color = nil;
	
	color = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] 
															  objectForKey:VFFixationColorKey]];	
	if (!inSummaryMode) {			
		VFFixation *currentFixation;
		int i = 0;
		BOOL foundFixation = NO;
		for (; i < [fixationsArray count]; i++) {
			currentFixation = [fixationsArray objectAtIndex:i];
			if (([currentFixation.startTime doubleValue] <= currentTime) 
				&& ([currentFixation.endTime doubleValue] >= currentTime)) {
				foundFixation = YES;
				break;
			} else if ([currentFixation.startTime doubleValue] >= currentTime) {
				foundFixation = NO;
				break;
			}
		}
		if (foundFixation) {
			if (i > 0) {
				[color set];
				VFFixation *previousFixation = [fixationsArray objectAtIndex:i-1];
				
				NSBezierPath *linePath = [NSBezierPath bezierPath];
				[linePath moveToPoint:previousFixation.location];
				[linePath lineToPoint:currentFixation.location];
				[linePath stroke];
			}
			[self drawFixation:currentFixation withColor:color];
		}
	} else {
		for (int i = 0; i < [fixationsArray count]; i++) {
			VFFixation *currentFixation = [fixationsArray objectAtIndex:i];
			// TODO: The alpha component seems not working.
			NSColor *colorToDraw = [color shadowWithLevel:0.7*pow((viewEndTime - [currentFixation.startTime doubleValue]) / (viewEndTime - viewStartTime), 0.7)];
			
			[self drawFixation:currentFixation withColor:colorToDraw];
			
			// Draw a line from last fixation to this one.
			if (i > 0) {
				VFFixation *lastFixation = [fixationsArray objectAtIndex:i - 1];
				
				NSBezierPath *linePath = [NSBezierPath bezierPath];
				[linePath moveToPoint:lastFixation.location];
				[linePath lineToPoint:currentFixation.location];
				[linePath stroke];
			}
		}
	}
}

- (void)drawFixation:(VFFixation *)aFixation withColor:(NSColor *)color
{
	[color set];
	double x = aFixation.location.x;
	double y = aFixation.location.y;
	NSRect innerRect = NSMakeRect( x - 3.0, y - 3.0, 6.0, 6.0);
	
	NSBezierPath *fixLocPath = [NSBezierPath bezierPathWithOvalInRect:innerRect];
	[fixLocPath fill];
	
	double radius;
	if (inSummaryMode)
		radius = pow([aFixation.endTime intValue] - [aFixation.startTime intValue], 0.4);
	else
		radius = pow(currentTime - [aFixation.startTime intValue], 0.4);
	NSRect durationRect = NSMakeRect(x - radius , y - radius, 2 * radius, 2 * radius);
	NSBezierPath *durationPath = [NSBezierPath bezierPathWithOvalInRect:durationRect];	
	[durationPath setLineWidth:2];
	
	[durationPath stroke];
	
	
	[[color colorWithAlphaComponent:0.4] setFill];
	[durationPath fill];
}

- (IBAction)changeViewScale:(id)sender
{
	sender = (NSComboBox *)sender;
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
	
	self.viewScale = [[numberFormatter numberFromString:[sender objectValueOfSelectedItem]] doubleValue];
	
	[self setFrameSize:NSMakeSize(session.screenResolution.width * viewScale, 
								  session.screenResolution.height * viewScale)];
}

@end
