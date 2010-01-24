//
//  VFView.m
//  VizFix
//
//  Created by Yunfeng Zhang on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VFView.h"

@implementation VFView

- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate;
{
	if (visualStimulusTemplate.fillColor != nil) {
		[visualStimulusTemplate.fillColor setFill];
		[visualStimulusTemplate.bound fill];
	}
}

- (void)drawGazes 
{
	int i=0;
	NSArray *gazes = [gazeSampleController arrangedObjects];
	for (VFGazeSample *eachGaze in gazes)
	{
		//	TEH I should add conditions so that samples outside
		//	the session screen resolution do not draw.
		if([[eachGaze valueForKey:@"valid"] boolValue])
		{
			//	Increase the brightness and decrease saturation as the samples progress
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
- (void)drawRect:(NSRect)rect
{
	//Save the previous graphics state
	[NSGraphicsContext saveGraphicsState];
	
	[[NSColor grayColor] setFill];
	[NSBezierPath fillRect:rect];

	// Draw screen objects.
	for (int i = 0; i < [[visualStimuliController arrangedObjects] count]; i++)
	{
		[visualStimuliController setSelectionIndex:i];
		VFVisualStimulus * eachVisualStimulus = [[visualStimuliController selectedObjects] objectAtIndex:0];
		for (VFVisualStimulusFrame *eachFrame in [visualStimulusFramesController arrangedObjects]) {
			NSAffineTransform *transform = [NSAffineTransform transform];
			// Transform the coordinate system to the origin of the ScreenOjbect
			[transform translateXBy:eachFrame.location.x yBy:eachFrame.location.y];	
			[transform concat];
			
			[self drawVisualStimulusTemplate:eachVisualStimulus.template];
			
			[transform invert];
			[transform concat];
			[eachVisualStimulus.label drawAtPoint:eachFrame.location
			 withAttributes:[NSDictionary dictionaryWithObject:[NSColor whiteColor] 
														forKey:NSForegroundColorAttributeName]];
		}
	}
	
	// Draw gazes.
	[self drawGazes];
	
	// Draw fixations
	NSArray *fixations = [fixationController arrangedObjects];
	
	for (int i = 0; i < [fixations count]; i++) {
		VFFixation *currentFixation = [fixations objectAtIndex:i];
		double x = currentFixation.location.x;
		double y = currentFixation.location.y;
		
		NSColor *color;
		if ([fixations count] == 1) {
			color = [NSColor colorWithCalibratedHue:0.75 
												  saturation:0.5 
												  brightness:1.0 
													   alpha:1.0];
		} else {
			color = [NSColor colorWithCalibratedHue:0.75 
												  saturation:(1.0 - ((i / (float)[fixations count]) / 2.0)) 
												  brightness:(0.5 + ((i / (float)[fixations count]) / 2.0)) 
													   alpha:1.0];
		}
						  
		[color setFill];
		[color setStroke];
		NSRect innerRect = NSMakeRect( x - 3.0, y - 3.0, 6.0, 6.0);
		
		NSBezierPath *fixLocPath = [NSBezierPath bezierPathWithOvalInRect:innerRect];
		[fixLocPath fill];
		
		double radius = log([currentFixation.endTime intValue] - [currentFixation.startTime intValue]) * 2;
		NSRect durationRect = NSMakeRect(x - radius , y - radius, 2 * radius, 2 * radius);
		NSBezierPath *durationPath = [NSBezierPath bezierPathWithOvalInRect:durationRect];	
		[durationPath setLineWidth:2];
		
		[durationPath stroke];
		
		// Draw a line from last fixation to this one.
		if (i > 0) {
			VFFixation *lastFixation = [fixations objectAtIndex:i - 1];
			
			NSBezierPath *linePath = [NSBezierPath bezierPath];
			[linePath moveToPoint:lastFixation.location];
			[linePath lineToPoint:currentFixation.location];
			[linePath stroke];
		}
	}
	
	//	Restore the previous graphics state
	//	saved at the beginning of this method
	[NSGraphicsContext restoreGraphicsState];	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == visualStimuliController && [keyPath isEqualToString:@"filterPredicate"])
	{
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (NSArray*)zorderSortDescriptor
{
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"zorder" ascending:YES];
	return [NSArray arrayWithObject:sort];
}

@end
