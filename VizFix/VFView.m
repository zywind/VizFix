//
//  VFView.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VFView.h"

@implementation VFView

@synthesize showLabel;
@synthesize showAutoAOI;
@synthesize inSummaryMode;
@synthesize dataURL;
@synthesize viewScale;
@synthesize showGazeSample;

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
	[self setNeedsDisplay:YES];	
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
	for (int i = 0; i < [[visualStimuliController arrangedObjects] count]; i++)
	{
		[visualStimuliController setSelectionIndex:i];
		NSArray *frames = [visualStimulusFramesController arrangedObjects];
		
		// In summary mode.
		if (!inSummaryMode) {
			VFVisualStimulusFrame *frame = [frames objectAtIndex:0];
			[self drawFrame:frame];
		} else {
			// TODO: Make this more general. For example, test the location difference between two frames.
			for (int j = 0; j < [frames count]; j = j+20) {
				VFVisualStimulusFrame *eachFrame = [frames objectAtIndex:j];
				[self drawFrame:eachFrame];
			}
		}
	}
	
	if (showGazeSample) {
		[self drawGazes];
	}
	
	// Draw fixations
	[self drawFixations];
	
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
	
	[self drawVisualStimulusTemplate:frame.ofVisualStimulus.template];
	if (showLabel) {
		[frame.ofVisualStimulus.label drawAtPoint:NSMakePoint(0, 0)
		 withAttributes:[NSDictionary dictionaryWithObject:[NSColor whiteColor] 
													forKey:NSForegroundColorAttributeName]];
	}
	
	[transform invert];
	[transform concat];
}

- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate
{
	NSPoint center;
	if (visualStimulusTemplate.fillColor != nil) {
		[visualStimulusTemplate.fillColor setFill];
		[visualStimulusTemplate.bound fill];
		center = NSMakePoint(NSMidX([visualStimulusTemplate.bound bounds]), 
							 NSMidY([visualStimulusTemplate.bound bounds]));
	} else if (visualStimulusTemplate.imageFilePath != nil) {
		NSURL *imageURL = [NSURL URLWithString:visualStimulusTemplate.imageFilePath 
								 relativeToURL:dataURL];
		
		NSImage *stimulusImage = [imageCacheDict valueForKey:visualStimulusTemplate.imageFilePath];
		if (stimulusImage == nil) {
			stimulusImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
			// Cache loaded images.
			[imageCacheDict setValue:stimulusImage forKey:visualStimulusTemplate.imageFilePath];
			
			if (stimulusImage == nil) {
				NSLog(@"Image file %@ does not exist.", [imageURL path]);
			}
		}
		
		center = NSMakePoint([stimulusImage size].width / 2, [stimulusImage size].height / 2);
		
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
	
	// If it's drawing background, there's no need to draw auto-AOI.
	if (![visualStimulusTemplate.category isEqualToString:@"background"] && showAutoAOI) {
		double width = [DOVConverter horizontalPixelsFromVisualAngles:1.0];
		double height = [DOVConverter verticalPixelsFromVisualAngles:1.0];
		
		NSRect foveaZoneRect = NSMakeRect(center.x - width/2, center.y - height/2, width, height);
		
		NSBezierPath *foveaZonePath = [NSBezierPath bezierPathWithOvalInRect:foveaZoneRect];
		
		[[NSColor grayColor] set];
		[foveaZonePath stroke];
	}
}

- (void)drawGazes 
{
	int i=0;
	NSArray *gazes = [gazeSampleController arrangedObjects];
	for (VFGazeSample *eachGaze in gazes)
	{
		// TEH I should add conditions so that samples outside
		// the session screen resolution do not draw.
		if([[eachGaze valueForKey:@"valid"] boolValue])
		{
			// Increase the brightness and decrease saturation as the samples progress
			[[NSColor colorWithCalibratedHue:0.5 
								  saturation:(1.0 - ((i / (float)[gazes count]) / 2.0)) 
								  brightness:(0.5 + ((i / (float)[gazes count]) / 2.0))
									   alpha:1.0] setFill];
		} else {
			[[NSColor blackColor] setFill];
		}
		NSRect aRect = NSMakeRect(eachGaze.location.x, eachGaze.location.y, 2.0, 2.0);
		NSRectFill(aRect);
		
		i++;
	}
	
}

- (void)drawFixations
{
	NSArray *fixations = [fixationController arrangedObjects];
	
	for (int i = 0; i < [fixations count]; i++) {
		VFFixation *currentFixation = [fixations objectAtIndex:i];
		double x = currentFixation.location.x;
		double y = currentFixation.location.y;
		
		NSColor *color;
		if ([fixations count] == 1) {
			color = [NSColor colorWithCalibratedHue:0.8 
										 saturation:0.5 
										 brightness:1.0 
											  alpha:1.0];
		} else {
			color = [NSColor colorWithCalibratedHue:0.8 
										 saturation:(1.0 - ((i / (float)[fixations count]) / 2.0)) 
										 brightness:(0.5 + ((i / (float)[fixations count]) / 2.0)) 
											  alpha:1.0];
		}
		
		[color set];
		NSRect innerRect = NSMakeRect( x - 3.0, y - 3.0, 6.0, 6.0);
		
		NSBezierPath *fixLocPath = [NSBezierPath bezierPathWithOvalInRect:innerRect];
		[fixLocPath fill];
		
		double radius = log([currentFixation.endTime intValue] - [currentFixation.startTime intValue]) * 2;
		NSRect durationRect = NSMakeRect(x - radius , y - radius, 2 * radius, 2 * radius);
		NSBezierPath *durationPath = [NSBezierPath bezierPathWithOvalInRect:durationRect];	
		[durationPath setLineWidth:2];
		
		[durationPath stroke];
		[[color colorWithAlphaComponent:0.4] setFill];
		[durationPath fill];
		
		// Draw a line from last fixation to this one.
		if (i > 0) {
			VFFixation *lastFixation = [fixations objectAtIndex:i - 1];
			
			NSBezierPath *linePath = [NSBezierPath bezierPath];
			[linePath moveToPoint:lastFixation.location];
			[linePath lineToPoint:currentFixation.location];
			[linePath stroke];
		}
	}
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
