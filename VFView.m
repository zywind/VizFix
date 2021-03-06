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
@synthesize showDistanceGuide;
@synthesize showScanpath;
@synthesize dataURL;
@synthesize viewScale;
@synthesize showGazeSample;
@synthesize showUncorrectedFixations;
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
		showScanpath = YES;
		showDistanceGuide = NO;
		[self addObserver:self forKeyPath:@"showLabel" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"showDistanceGuide" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"showGazeSample" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"showScanpath" options:NSKeyValueObservingOptionNew context:NULL];
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
	[self setFrameSize:NSMakeSize(session.screenResolution.width + 500, session.screenResolution.height + 500)];
	
	fetchHelper = [[VFFetchHelper alloc] initWithMOC:[aSession managedObjectContext]];
}

//- (BOOL)isFlipped
//{
//    if (session) {
//        return session.flippedCoordinates;
//    } else return NO;
//}

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
    
    NSAffineTransform* xform = [NSAffineTransform transform];
    [xform scaleXBy:viewScale yBy:viewScale];
	[xform translateXBy:250 yBy:250];
	[xform concat];
	
	distanceGuideSizeDOV = [[NSUserDefaults standardUserDefaults] floatForKey:VFDistanceGuideSizeKey];
    [session.backgroundColor drawSwatchInRect:NSMakeRect(0, 0, session.screenResolution.width, session.screenResolution.height)];


//	NSAffineTransform* xform = [NSAffineTransform transform];
	
	// Draw background.
	
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
	
    // Temporary, just for Williams experiment YZ 12-6-2012
    NSDictionary *thresDict = @{@"small" : @1.0, @"medium" : @1.4, @"large" : @2.0};
    NSString *size = [[theStimulus.ID componentsSeparatedByString:@", "] lastObject];
    double thres = [thresDict[size] doubleValue];
   
	[self drawVisualStimulusTemplate:theStimulus.template withAlpha:alpha withDistanceGuideSize:thres];
	// Depends on the label font size.
	if (showLabel) {
        NSAffineTransform* xform = [NSAffineTransform transform];
        [xform scaleXBy:1/viewScale yBy:1/viewScale];
        [xform concat];
        
		[theStimulus.label drawAtPoint:NSMakePoint(-7, -7)
		 withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSBackgroundColorAttributeName, 
									[NSColor blackColor], NSForegroundColorAttributeName, nil]];
        
        [xform invert];
        [xform concat];
	}
	
	[transform invert];
	[transform concat];
}

- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate withAlpha:(double)alpha withDistanceGuideSize:(double)size
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
	
	// If it's drawing background, there's no need to draw distance guide.
	if (showDistanceGuide && ![visualStimulusTemplate.category isEqualToString:@"background"] 
		&& (visualStimulusTemplate.fixationPoint.x != 1.0e+5f)) {
//		NSSize distanceGuideSize = NSMakeSize([DOVConverter pixelsFromVisualAngles:distanceGuideSizeDOV], [DOVConverter pixelsFromVisualAngles:distanceGuideSizeDOV]);
//      temporary
        NSSize distanceGuideSize = NSMakeSize([DOVConverter pixelsFromVisualAngles:size], [DOVConverter pixelsFromVisualAngles:size]);
		NSBezierPath *foveaZonePath = [VFUtil distanceGuideAroundPoint:visualStimulusTemplate.fixationPoint withSize:distanceGuideSize];
		
        NSColor *guideColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]
                                                                                    objectForKey:VFDistanceGuideColorKey]];
        
		[guideColor set];
        [foveaZonePath setLineWidth:3];
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
			if (showScanpath && i > 0) {
				[color set];
				VFFixation *previousFixation = [fixationsArray objectAtIndex:i-1];
				
				NSBezierPath *linePath = [NSBezierPath bezierPath];
				[linePath moveToPoint:previousFixation.location];
				[linePath lineToPoint:currentFixation.location];
                [linePath setLineWidth:3.0];
				[linePath stroke];
			}
			[self drawFixation:currentFixation withColor:color];
            if (self.showUncorrectedFixations && currentFixation.relatedFixation)
                [self drawFixation:currentFixation.relatedFixation withColor:[NSColor grayColor]];
		}
	} else {
		for (int i = 0; i < [fixationsArray count]; i++) {
			VFFixation *currentFixation = [fixationsArray objectAtIndex:i];
            
            NSColor *colorToDraw = [color shadowWithLevel:(viewEndTime - [currentFixation.startTime doubleValue]) / (viewEndTime - viewStartTime)];
//            NSColor *colorToDraw = color;
           
			[self drawFixation:currentFixation withColor:colorToDraw];
            
            if (self.showUncorrectedFixations && currentFixation.relatedFixation) {
                NSColor *colorForUncorrectedFixations = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]
                                                                                                          objectForKey:VFUncorrectedFixationColorKey]];
                
                [self drawFixation:currentFixation.relatedFixation withColor:colorForUncorrectedFixations];
            }
			
			// Draw a line from last fixation to this one.
			if (showScanpath && i > 0) {
                [colorToDraw set];
				VFFixation *lastFixation = [fixationsArray objectAtIndex:i - 1];
				
				NSBezierPath *linePath = [NSBezierPath bezierPath];
				[linePath moveToPoint:lastFixation.location];
				[linePath lineToPoint:currentFixation.location];
//                [linePath setLineWidth:3.0];
                [linePath setLineWidth:2.0];
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
//    [[color colorWithAlphaComponent:0.8] setFill];
	[durationPath fill];
}

- (IBAction)changeViewScale:(id)sender
{
	sender = (NSComboBox *)sender;
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
	
	self.viewScale = [[numberFormatter numberFromString:[sender objectValueOfSelectedItem]] doubleValue];
	
	[self setFrameSize:NSMakeSize((session.screenResolution.width + 500) * viewScale,
								  (session.screenResolution.height + 500) * viewScale)];
}

- (BOOL)isFlipped
{
    return self.flippedView;
}

@end
