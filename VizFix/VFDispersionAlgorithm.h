//
//  VFDispersionAlgorithm.h
//  VizFixX
//
//  Created by Tim Halverson on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//
//	This class defines a fixation detection plugin as defined in VFPluginProtocols.h
//	This plugin contains the default fixation detection algorithms, namely dispersion-based.
//	The dispersion based algorithm defined here has the following properties:
//	1) A sample is considered to be within the dispersion threshold and part of an ongoing
//		fixation if the sample is less than 'radius' units (usually pixels) from the center
//		of gravity of all previous, contiguous samples that are in the current potential fixation.
//	2) To accomodate blinks, invalid (e.g. eye not found) samples are considered part of an ongoing
//		fixation if:
//			a) the next valid sample is less than 'radius' units from the center of gravity of the
//				current fixation.
//			b) the number of contiguous invalid samples is less than 'minFixSamples'.
//	3) To accomodate noise, a single sample that is greater than 'radius' units from the center
//		of gravity of the current fixation is considered part of the current fixation if the
//		following sample falls back with the 'radius' units.
//


#import <Cocoa/Cocoa.h>
#import "VFGazeSample.h"
#import "VFScreenLocation.h"
#import "VFFixation.h"
#import "VFTimeSpan.h"

@interface VFDispersionAlgorithm : NSObject
{
	//	Preferences variables
	float radius;
	NSUInteger minFixSamples;
}

@property (nonatomic, assign) float radius;
@property (nonatomic, assign) NSUInteger minFixSamples;

- (float)distanceBetweenThisPoint:(NSPoint)center andThatPoint:(NSPoint)point;
- (void)detectFixation:(NSArray *)gazeArray inMOC:(NSManagedObjectContext *)moc;
@end
