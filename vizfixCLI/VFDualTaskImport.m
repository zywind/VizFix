//
//  VFDualTaskImport.m
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 1/14/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import "VFDualTaskImport.h"


@implementation VFDualTaskImport

@synthesize moc;
@synthesize lineNum;

- (VFDualTaskImport *)initWithMOC:(NSManagedObjectContext *)anMOC
{	
	if (self = [super init]) {
		[anMOC setUndoManager:nil];
		self.moc = anMOC;
		self.lineNum = 0;
    }
    return self;
}

- (void)import:(NSURL *)rawDataFileURL
{
	session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:moc];
	session.distanceToScreen = [NSNumber numberWithInt:6098]; // in mm.
	session.screenResolutionWidth = [NSNumber numberWithInt:1280]; // in pixel.
	session.screenResolutionHeight = [NSNumber numberWithInt:1024];
	session.experiment = @"NRL Dual Task";
	session.gazeSampleRate = [NSNumber numberWithInt:120]; // per second.
	session.screenDimensionWidth = [NSNumber numberWithInt:432]; // in mm.
	session.screenDimensionHeight = [NSNumber numberWithInt:407]; // in mm.
	
	
	// TODO: load background bmp
	
	// Parse participant ID from raw data file name	
	session.subjectID = [[[rawDataFileURL absoluteString] lastPathComponent] substringToIndex:3];
	// TODO: parse session ID.
	session.sessionID = [[[rawDataFileURL absoluteString] lastPathComponent] substringToIndex:3];
	
	NSArray  *matchArray = nil;
	NSString *regexStr = @"Sound\%20(\\w*)\%20Gaze\%20(\\w*)";
	
	// Parse scenario conditions.
	// Parse sound condition.
	soundCondition = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	soundCondition.factor = @"sound";
	// Get the position of the initial character of the sound condition.
	matchArray = [[[rawDataFileURL absoluteString] lastPathComponent] arrayOfCaptureComponentsMatchedByRegex:regexStr];
	soundCondition.level = [[matchArray objectAtIndex:0] objectAtIndex:1];
	// Parse gaze condition.
	gazeCondition = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	gazeCondition.factor = @"gaze";
	// Get the position of the initial character of the gaze condition.
	gazeCondition.level = [[matchArray objectAtIndex:0] objectAtIndex:2];
		
	// Read raw data file.	
	NSError *error;
	NSString *fileContents = [NSString stringWithContentsOfURL:rawDataFileURL encoding:NSUTF8StringEncoding 
														 error:&error];
	if (fileContents == nil) {
		NSLog(@"Reading raw data file contents failed.\n%@", 
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
		return;
	}
	lines = [fileContents componentsSeparatedByString:@"\n"];
	
	// Parse date.
	matchArray = nil;
	regexStr = @"^\\d\\tDate\\t(\\d{4})(\\d{2})(\\d{2})_(\\d{2})(\\d{2})(\\d{2})$";
	
	matchArray = [[lines objectAtIndex:lineNum++] arrayOfCaptureComponentsMatchedByRegex:regexStr];
	NSEnumerator *matchEnumerator = [[matchArray objectAtIndex:0] objectEnumerator];
	[matchEnumerator nextObject];
	// Constructing date.
	NSMutableString *date = [NSMutableString stringWithCapacity:10] ;
	for (int i = 0; i < 2; i++) {
		[date appendString:[matchEnumerator nextObject]];
		[date appendString:@"-"]; 
	}
	[date appendString:[matchEnumerator nextObject]];
	
	// Constructing time.
	NSMutableString *time = [NSMutableString stringWithCapacity:10] ;
	for (int i = 0; i < 2; i++) {
		[time appendString:[matchEnumerator nextObject]];
		[time appendString:@":"]; 
	}
	[time appendString:[matchEnumerator nextObject]];
	
	// Time Zone string.
	NSString *timeZone = @"+0800";
	// Finally, save date. 
	session.date = [NSDate dateWithString:[NSString stringWithFormat:@"%@ %@ %@", date, time, timeZone]];
	
	[self prepareImport];
	
	// Main loop.	
	//	The next line must contains at least 2 columns.
	while(([currentLineFields = [[lines objectAtIndex:lineNum++] componentsSeparatedByString:@"\t"] 
			count] > 1)
		  && lineNum < [lines count])
	{		
		if ([[currentLineFields objectAtIndex:1] isEqualToString:@"EyeGaze"]) {
			[self importGaze];
		} else if([[currentLineFields objectAtIndex:1] isEqualToString:@"Comment"]) {
			if ([[currentLineFields objectAtIndex:2] isEqualToString:@"wave_start"]) {				
				[self startBlock];
			} else if ([[currentLineFields objectAtIndex:2] isEqualToString:@"wave_end"]) {
				[self endBlock];
			} else {
				// TODO: error handliing.
				NSLog(@"Unknow comment.");
			}
		} else if ([[currentLineFields objectAtIndex:1] isEqualToString:@"BlipAppeared"]) {			
			[self startTrial];
		} else if ([[currentLineFields objectAtIndex:1] isEqualToString:@"BlipMoved"]) {
			[self parseBlipMoved];
		} else if ([[currentLineFields objectAtIndex:1] isEqualToString:@"BlipChangedColor"]) {
			[self parseBlipChangedColor];
		} else if ([[currentLineFields objectAtIndex:1] isEqualToString:@"BlipDisappeared"]) {
			[self parseBlipDisappeared];
		} else if ([[currentLineFields objectAtIndex:1] isEqualToString:@"TrialData"]) {
			[self endTrial];
		}
	}
	
	for (VFGazeSample *gaze in ongoingGazes) {
		[moc deleteObject:gaze];
	}
	NSLog(@"Discarded %d gaze samples.", discardedGazeCount);
	[ongoingGazes removeAllObjects];
	
	// Import completed. Save.
	if (![moc save:&error])
	{
		NSLog(@"Data Import Failure\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
		NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		NSLog(@"%u validation errors have occurred", [detailedErrors count]);
		for (NSError *detailError in detailedErrors) {
			NSLog(@"%@\n%@", [detailError localizedDescription], [[detailError userInfo] objectForKey:NSValidationObjectErrorKey]);
		}
	}
}

- (void)prepareImport
{
	// Initialize five wave siz conditions.
	waveSizeOne = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveSizeOne.factor = @"wave size";
	waveSizeOne.level = @"1";
	waveSizeTwo = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveSizeTwo.factor = @"wave size";
	waveSizeTwo.level = @"2";
	waveSizeFour = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveSizeFour.factor = @"wave size";
	waveSizeFour.level = @"4";
	waveSizeSix = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveSizeSix.factor = @"wave size";
	waveSizeSix.level = @"6";
	waveSizeEight = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveSizeEight.factor = @"wave size";
	waveSizeEight.level = @"8";
	
	waveTypeRandom = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveTypeRandom.factor = @"wave type";
	waveTypeRandom.level = @"ran";
	waveTypePreclassifiable = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	waveTypePreclassifiable.factor = @"wave type";
	waveTypePreclassifiable.level = @"pre";
	
	blipTypeFighter = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipTypeFighter.factor = @"blip type";
	blipTypeFighter.level = @"fighter";
	blipTypeSupport = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipTypeSupport.factor = @"blip type";
	blipTypeSupport.level = @"support";
	blipTypeMissile = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipTypeMissile.factor = @"blip type";
	blipTypeMissile.level = @"missile";
	
	blipDesignationHostile = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipDesignationHostile.factor = @"blip designation";
	blipDesignationHostile.level = @"hostile";
	blipDesignationNeutral = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipDesignationNeutral.factor = @"blip designation";
	blipDesignationNeutral.level = @"neutral";
	
	blipSensorFail = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipSensorFail.factor = @"sensor fail";
	blipSensorFail.level = @"yes";
	blipSensorNotFail = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	blipSensorNotFail.factor = @"sensor fail";
	blipSensorNotFail.level = @"no";
	
	trackNumConditions = [NSMutableArray arrayWithCapacity:9];
	for (int i =  1; i <= 9; i++) {
		VFCondition *tempCondition = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
		tempCondition.factor = @"track number";
		tempCondition.level = [[NSNumber numberWithInt:i] stringValue];

		[trackNumConditions addObject:tempCondition];
	}
	
	NSBezierPath *fighterPath = [NSBezierPath bezierPath];
	[fighterPath moveToPoint:NSMakePoint(0, 0)];
	[fighterPath lineToPoint:NSMakePoint(32, 0)];
	[fighterPath lineToPoint:NSMakePoint(16, 32)];
	[fighterPath closePath];
	NSBezierPath *supportPath = [NSBezierPath bezierPath];
	[supportPath moveToPoint:NSMakePoint(16, 0)];
	[supportPath lineToPoint:NSMakePoint(0, 16)];
	[supportPath lineToPoint:NSMakePoint(16, 32)];
	[supportPath lineToPoint:NSMakePoint(32, 16)];
	[supportPath closePath];
	NSBezierPath *missilePath = [NSBezierPath bezierPath];
	[missilePath appendBezierPathWithOvalInRect:NSMakeRect(0, 0, 32, 32)];
	[missilePath closePath];
	
	NSArray *blipTypePaths = [NSArray arrayWithObjects:fighterPath, supportPath, missilePath, nil];
	NSArray *blipColors = [NSArray arrayWithObjects:[NSColor blackColor], [NSColor greenColor], 
													[NSColor redColor], [NSColor whiteColor],
													[NSColor yellowColor], nil];
	
	NSMutableArray *tempTemplates = [NSMutableArray arrayWithCapacity:15];
	for (int i = 0; i < 5; i++) {
		for (int j = 0; j < 3; j++) {
			VFVisualStimulusTemplate *aBlipTemplate = 
				[NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusTemplate" inManagedObjectContext:moc];
			
			aBlipTemplate.bound = [blipTypePaths objectAtIndex:j];
			aBlipTemplate.fillColor = [blipColors objectAtIndex:i];
			aBlipTemplate.category = @"blip";
			
			[tempTemplates addObject:aBlipTemplate];
		}
	}
	
	visualStimuliTemplates = [NSArray arrayWithArray:tempTemplates];
	
	blipColorCodes = [NSArray arrayWithObjects:@"0", @"1", @"2", @"5", @"7", nil];
	
	// Initialize temporary containers.
	ongoingBlips = [NSMutableDictionary dictionaryWithCapacity:10];
	ongoingTrials = [NSMutableDictionary dictionaryWithCapacity:10];
	ongoingGazes = [NSMutableArray arrayWithCapacity:10];
	
	discardedGazeCount = 0;
}

- (void)importGaze
{
	static int lastGazeTimeStamp = 0;
	static int startAccumulateTimeStamp = 0;
	static BOOL consolidateState = 0;
	// If it is not preparing to consolidate, record and accumulate the gaze sample, but does not record its time stamp.
	if (consolidateState == 0) {
		[ongoingGazes addObject:[self makeGazeSample]];
		// Check if the current time stamp is the same as the last one. If so, increment consolidate state.
		if ([[currentLineFields objectAtIndex:0] intValue] == lastGazeTimeStamp) {
			consolidateState = 1;
		} else {
			lastGazeTimeStamp = [[currentLineFields objectAtIndex:0] intValue];
		}
	} else if (consolidateState == 1) {
		[ongoingGazes addObject:[self makeGazeSample]];
		if ([[currentLineFields objectAtIndex:0] intValue] != lastGazeTimeStamp) {
			consolidateState = 2;
			lastGazeTimeStamp = [[currentLineFields objectAtIndex:0] intValue];
		}
	} else if (consolidateState == 2) {
		if ([[currentLineFields objectAtIndex:0] intValue] != lastGazeTimeStamp) {
			// Two different records appeared. Now start the consolidating process.
			NSUInteger consolidateEndTimeStamp = [((VFGazeSample *)[ongoingGazes objectAtIndex:([ongoingGazes count] - 2)]).time intValue];
			float timePerGaze = (float)(consolidateEndTimeStamp - startAccumulateTimeStamp) / (float)([ongoingGazes count] - 1);
			// Sample rate cannot be larger than 122. If so, use 8.2.
			if (timePerGaze < 8.2)
				timePerGaze = 8.2;
			// Assign time backwards.
			for (int i = [ongoingGazes count] - 2; i >= 0; i--) {
				int assignTime = consolidateEndTimeStamp - (NSUInteger) (timePerGaze * ([ongoingGazes count] - 2 - i));
				if (assignTime <= startAccumulateTimeStamp || assignTime > [((VFGazeSample *)[ongoingGazes objectAtIndex:i]).time intValue]  + 10) {
					//NSLog(@"Discard the gaze sample of time stamp %d for it is less than %d", assignTime, startAccumulateTimeStamp);
					[moc deleteObject:[ongoingGazes objectAtIndex:i]];
					discardedGazeCount++;
				} else {
					((VFGazeSample *)[ongoingGazes objectAtIndex:i]).time = [NSNumber numberWithUnsignedInt:assignTime];
					[currentBlock addGazeSamplesObject:[ongoingGazes objectAtIndex:i]];
				}
			}
			
			[ongoingGazes removeObjectsInRange:NSMakeRange(0, [ongoingGazes count] - 1)];
			// Consolidating finished.
			consolidateState = 0;
			startAccumulateTimeStamp = consolidateEndTimeStamp;
			// Record the new gaze sample.
			[ongoingGazes addObject:[self makeGazeSample]];
			lastGazeTimeStamp = consolidateEndTimeStamp;
		} else {
			consolidateState = 1;
		}
	}
}
		 
- (void)startBlock
{
	currentBlock = [NSEntityDescription insertNewObjectForEntityForName:@"Block" inManagedObjectContext:moc];	
	[session addBlocksObject:currentBlock];
	
	currentBlock.ID = [@"wave " stringByAppendingString:[currentLineFields objectAtIndex:3]];
	currentBlock.order = [NSNumber numberWithInt:[currentBlock.ID intValue]];
	currentBlock.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	
	[currentBlock addConditionsObject:gazeCondition];
	[currentBlock addConditionsObject:soundCondition];
	
	// Import conditions
	NSString *waveSize = [currentLineFields objectAtIndex:4];
	if ([waveSize isEqualToString:@"1"]) {		
		[currentBlock addConditionsObject:waveSizeOne];
	} else if ([waveSize isEqualToString:@"2"]) {
		[currentBlock addConditionsObject:waveSizeTwo];
	} else if ([waveSize isEqualToString:@"4"]) {
		[currentBlock addConditionsObject:waveSizeFour];
	} else if ([waveSize isEqualToString:@"6"]) {
		[currentBlock addConditionsObject:waveSizeSix];
	} else if ([waveSize isEqualToString:@"8"]) {
		[currentBlock addConditionsObject:waveSizeEight];
	}
	NSString *waveType = [currentLineFields objectAtIndex:5];
	if ([waveType isEqualToString:@"ran"]) {
		[currentBlock addConditionsObject:waveTypeRandom];
	} else if ([waveType isEqualToString:@"pre"]) {
		[currentBlock addConditionsObject:waveTypePreclassifiable];
	}
}

- (void)endBlock
{
	currentBlock.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	
	// TODO: Consolidate ongoing gaze samples.
	currentBlock = nil;
	
	// TODO: Validate if the end comment has the same string as the start comment.
}

- (void)startTrial
{
	VFTrial *trial = [NSEntityDescription insertNewObjectForEntityForName:@"Trial" inManagedObjectContext:moc];
	[currentBlock addTrialsObject:trial];
	trial.ID = [@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]];
	trial.order = [NSNumber numberWithInt:[trial.ID intValue]];
	trial.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];

	[ongoingTrials setObject:trial forKey:trial.ID];

	if ([[currentLineFields objectAtIndex:5] isEqualToString:@"1"]) {
		[trial addConditionsObject:blipTypeFighter];
	} else if ([[currentLineFields objectAtIndex:5] isEqualToString:@"2"]) {
		[trial addConditionsObject:blipTypeSupport];
	} else if ([[currentLineFields objectAtIndex:5] isEqualToString:@"3"]) {
		[trial addConditionsObject:blipTypeMissile];
	}
	
	if ([[currentLineFields objectAtIndex:6] isEqualToString:@"1"]) {
		[trial addConditionsObject:blipDesignationNeutral];
	} else if ([[currentLineFields objectAtIndex:6] isEqualToString:@"2"]) {
		[trial addConditionsObject:blipDesignationHostile];
	}
	
	VFCondition *trackNumCondition = [trackNumConditions objectAtIndex:[[currentLineFields objectAtIndex:10] intValue] - 1];
	[trial addConditionsObject:trackNumCondition];
	
	// TODO: check the coding.
	if ([[currentLineFields objectAtIndex:7] isEqualToString:@"1"]) {
		[trial addConditionsObject:blipSensorFail];
	} else if ([[currentLineFields objectAtIndex:7] isEqualToString:@"0"]) {
		[trial addConditionsObject:blipSensorNotFail];
	}
	
	// Parse subTrial.
	VFSubTrial *subTrial = [NSEntityDescription insertNewObjectForEntityForName:@"SubTrial" inManagedObjectContext:moc];
	subTrial.ID = @"PreClassify";
	subTrial.startTime = trial.startTime;
	[trial addSubTrialsObject:subTrial];
	
	// Parse screen object.
	VFVisualStimulus *blip = [self makeBlip];
	blip.label = [currentLineFields objectAtIndex:10];
	blip.template = [visualStimuliTemplates objectAtIndex:[[currentLineFields objectAtIndex:5] intValue] - 1];
	
	[ongoingBlips setObject:blip forKey:blip.ID];
	
	VFVisualStimulusFrame *aFrame = [self makeBlipFrame];
	[blip addFramesObject:aFrame];
}

- (void)endTrial
{
	[self endLastSubTrial];

	VFTrial *trial = [ongoingTrials objectForKey:[@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]]];
	trial.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	// Add responses.
	VFResponse *response = [NSEntityDescription insertNewObjectForEntityForName:@"Response" inManagedObjectContext:moc];
	response.measure = @"First key RT";
	NSString *errorCode = [currentLineFields objectAtIndex:8];
	if ([errorCode isEqualToString:@"0"]) {
		response.error = @"correct";
		int RT = [[currentLineFields objectAtIndex:6] intValue] - [[currentLineFields objectAtIndex:5] intValue];
		response.value = [[NSNumber numberWithInt:RT] stringValue];
	} else if ([errorCode isEqualToString:@"1"]) {
		response.error = @"incorrect";
		int RT = [[currentLineFields objectAtIndex:6] intValue] - [[currentLineFields objectAtIndex:5] intValue];
		response.value = [[NSNumber numberWithInt:RT] stringValue];
	} else {
		response.error = @"missed";
		response.value = @"NA";
	}
	[trial addResponsesObject:response];
	[ongoingTrials removeObjectForKey:trial.ID];
}

#pragma mark -
#pragma mark -------PARSE BLIP EVENTS-------
- (void)parseBlipMoved
{
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[currentLineFields objectAtIndex:2]];
	[self endBlipFrameForBlip:blip];
	
	[blip addFramesObject:[self makeBlipFrame]];
}

- (void)parseBlipChangedColor
{
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[currentLineFields objectAtIndex:2]];
	[self endBlipFrameForBlip:blip];
	blip.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
	[ongoingBlips removeObjectForKey:[currentLineFields objectAtIndex:2]];
	
	int colorIndex = [blipColorCodes indexOfObject:[currentLineFields objectAtIndex:6]];
	int typeIndex = [[currentLineFields objectAtIndex:5] intValue] - 1;
	
	VFVisualStimulus *newBlip = [self makeBlip];
	newBlip.template = [visualStimuliTemplates objectAtIndex:(colorIndex * 3 + typeIndex)];
	[newBlip addFramesObject:[self makeBlipFrame]];
	[ongoingBlips setObject:newBlip forKey:newBlip.ID];
	
	// End last subTrial.
	[self endLastSubTrial];

	// Start new subTrial
	VFSubTrial *subTrial = [NSEntityDescription insertNewObjectForEntityForName:@"SubTrial" inManagedObjectContext:moc];
	if (![[currentLineFields objectAtIndex:6] isEqualToString:@"5"]) // It's not changing to white.
	{
		subTrial.ID = @"InClassify";
	} else {
		subTrial.ID = @"PostClassify";
	}
	subTrial.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	// Add it to trial's subTrials list.
	VFTrial *trial = [ongoingTrials objectForKey:[@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]]];
	[trial addSubTrialsObject:subTrial];
}


- (void)parseBlipDisappeared
{
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[currentLineFields objectAtIndex:2]];
	[self endBlipFrameForBlip:blip];
	blip.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
}

#pragma mark -
#pragma mark ------HELPER METHODS-------


- (void)endLastSubTrial {
	// End the last subTrial.
	VFTrial *trial = [ongoingTrials objectForKey:[@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]]];
	// End the previous subTrial.
	for (VFSubTrial *aSubTrial in [trial subTrials]) {
		if (aSubTrial.endTime == nil) {
			aSubTrial.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
			break;
		}
	}
}

- (NSPoint)makeLocation {
	// The output blip location indicates the position of the blip icon's left-top corner.
	NSPoint location;
	
	location.x = [[currentLineFields objectAtIndex:3] floatValue];
	location.y = [[currentLineFields objectAtIndex:4] floatValue];
	
	return location;
}

- (VFVisualStimulus *)makeBlip
{
	VFVisualStimulus *blip = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulus" inManagedObjectContext:moc];
	blip.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	blip.label = [currentLineFields objectAtIndex:7];
	blip.ID = [currentLineFields objectAtIndex:2];
	
	[currentBlock addVisualStimuliObject:blip];
	
	return blip;
}


- (VFVisualStimulusFrame *)makeBlipFrame
{
	VFVisualStimulusFrame *aFrame = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusFrame" inManagedObjectContext:moc];
	aFrame.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	aFrame.location = [self makeLocation];
		
	return aFrame;
}

- (void)endBlipFrameForBlip:(VFVisualStimulus *)blip
{	
	for (VFVisualStimulusFrame *aFrame in [blip frames]) {
		if (aFrame.endTime == nil) {
			aFrame.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
			break;
		}
	}
}

- (VFGazeSample *)makeGazeSample
{
	VFGazeSample *gaze = [NSEntityDescription insertNewObjectForEntityForName:@"GazeSample" inManagedObjectContext:moc];

	gaze.location = [self makeLocation];
	gaze.valid = [NSNumber numberWithBool:([[currentLineFields objectAtIndex:5] isEqualToString:@"1"]) ? YES : NO];
	gaze.time = [NSNumber numberWithUnsignedInt:[[currentLineFields objectAtIndex:0] intValue]];
			
	return gaze;
}
@end
