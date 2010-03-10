//
//  VFView.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/15/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

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
				
		autoAOISizeDOV = [[NSUserDefaults standardUserDefaults] floatForKey:VFAutoAOISizeKey];
	}
    return self;
}

- (void)setSession:(VFSession *)aSession
{
	session = aSession;
	DOVConverter = [[VFVisualAngleConverter alloc] initWithDistanceToScreen:[session.distanceToScreen intValue]
														   screenResolution:session.screenResolution 
															screenDimension:session.screenDimension];
	[self setFrameSize:session.screenResolution];
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

- (void)updateViewContentsFrom:(double)viewStartTime to:(double)viewEndTime
{
	if (session == nil)
		return;
	NSManagedObjectContext *moc = [session managedObjectContext];
	
	NSNumber *startTime = [NSNumber numberWithDouble:viewStartTime];
	NSNumber *endTime = [NSNumber numberWithDouble:viewEndTime];
	if (showGazeSample) {
		gazesArray = [VFUtil fetchModelObjectsForName:@"GazeSample" 
												 from:startTime 
												   to:endTime
											  withMOC:moc];
	} else {
		gazesArray = nil;
	}
	visualStimuliArray = [VFUtil fetchModelObjectsForName:@"VisualStimulus" 
													 from:startTime 
													   to:endTime
												  withMOC:moc];
	fixationsArray = [VFUtil fetchModelObjectsForName:@"Fixation" 
											   from:startTime 
												 to:endTime
											withMOC:moc];
	keyEventsArray = [VFUtil fetchModelObjectsForName:@"KeyboardEvent" 
												 from:startTime
												   to:endTime 
											  withMOC:moc];

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
	[xform concat];
	// Draw background.
	[self drawVisualStimulusTemplate:session.background];
	
	// Draw screen objects.
	for (VFVisualStimulus *vs in visualStimuliArray)
	{
		NSSet *frames = vs.frames;

		if (!inSummaryMode) {
			VFVisualStimulusFrame *aFrame = [[frames filteredSetUsingPredicate:playbackPredicateForTimePeriod] anyObject];
			if (aFrame != nil)
				[self drawFrame:aFrame];
		} else {
			NSArray *vsFrames = [[frames allObjects] sortedArrayUsingDescriptors:[VFUtil startTimeSortDescriptor]];
			VFVisualStimulusFrame *lastDrawnFrame;
			for (int i = 0; i < [vsFrames count]; i++) {
				VFVisualStimulusFrame *thisFrame = [vsFrames objectAtIndex:i];
				if (i == 0 || i == [vsFrames count] - 1 || 
					([VFUtil distanceBetweenThisPoint:thisFrame.location 
										 andThatPoint:lastDrawnFrame.location] >= 16)){
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
	[self drawVisualStimulusTemplate:theStimulus.template];
	// Depends on the label font size.
	if (showLabel) {
		[theStimulus.label drawAtPoint:NSMakePoint(0.0f, 0.0f)
		 withAttributes:[NSDictionary dictionaryWithObject:[NSColor whiteColor] 
													forKey:NSForegroundColorAttributeName]];
	}
	
	[transform invert];
	[transform concat];
}

- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate
{
	if (visualStimulusTemplate.fillColor != nil) {
		[visualStimulusTemplate.fillColor setFill];
		[visualStimulusTemplate.outline fill];
	} 
	
	if (visualStimulusTemplate.imageFilePath != nil) {
		NSURL *imageURL = [NSURL URLWithString:visualStimulusTemplate.imageFilePath 
								 relativeToURL:dataURL];
		
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
						  fraction:1.0];
		
		
		[xform invert];
		[xform concat];
	}
	
	if (visualStimulusTemplate.strokeColor != nil) {
		[visualStimulusTemplate.strokeColor setStroke];
		[visualStimulusTemplate.outline stroke];
	} 
	
	// If it's drawing background, there's no need to draw auto-AOI.
	if (![visualStimulusTemplate.category isEqualToString:@"background"] && showAutoAOI) {
		NSSize autoAOISize = NSMakeSize([DOVConverter horizontalPixelsFromVisualAngles:autoAOISizeDOV], 
										[DOVConverter verticalPixelsFromVisualAngles:autoAOISizeDOV]);
		NSBezierPath *foveaZonePath = [VFUtil autoAOIAroundCenter:visualStimulusTemplate.center withSize:autoAOISize];
		
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
	NSColor *color;
	if (!inSummaryMode) {			
		color = [NSColor colorWithCalibratedHue:0.8 
									 saturation:1.0 
									 brightness:1.0 
										  alpha:1.0];
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
			
			color = [NSColor colorWithCalibratedHue:0.8 
										 saturation:(1.0 - ((i / (float)[fixationsArray count]) / 2.0)) 
										 brightness:(0.5 + ((i / (float)[fixationsArray count]) / 2.0)) 
											  alpha:1.0];
						
			[self drawFixation:currentFixation withColor:color];
			
			
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
	
	double radius = log([aFixation.endTime intValue] - [aFixation.startTime intValue]) * 2;
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
