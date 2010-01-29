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
		moc = anMOC;
		[moc setUndoManager:nil];
		lineNum = 0;
		discardedGazeCount = 0;
		
		lastGazeTimeStamp = 0;
		startAccumulateTimeStamp = 0;
		consolidateState = 0;
    }
    return self;
}

- (void)import:(NSURL *)rawDataFileURL
{
	session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:moc];
	session.distanceToScreen = [NSNumber numberWithInt:610]; // in mm.
	session.screenResolution = NSMakeSize(1280.0, 1024.0); // in pixel.
	session.experiment = @"NRL Dual Task";
	session.gazeSampleRate = [NSNumber numberWithInt:120]; // per second.
	session.screenDimension = NSMakeSize(432.0, 407.0); // in mm.
	VFVisualStimulusTemplate *backgroundTemplate = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusTemplate"
																				 inManagedObjectContext:moc];
	backgroundTemplate.imageFilePath = @"img/background.png";
	backgroundTemplate.category = @"background";
	
	session.background = backgroundTemplate;
		
	NSString *fileName = [[rawDataFileURL path] lastPathComponent];
	
	// Parse participant ID from raw data file name	
	session.subjectID = [fileName substringToIndex:3];
	session.sessionID = [fileName substringWithRange:NSMakeRange(4,3)];
	
	NSArray  *matchArray = nil;
	NSString *regexStr = @"Sound (\\w*) Gaze (\\w*)";
	matchArray = [fileName arrayOfCaptureComponentsMatchedByRegex:regexStr];

	// Parse scenario conditions.
	// Parse sound condition.
	soundCondition = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
	soundCondition.factor = @"sound";
	// Get the position of the initial character of the sound condition.
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
	regexStr = @"^\\d\\tDate\\t(\\d{4})(\\d{2})(\\d{2})_(\\d{2})(\\d{2})(\\d{2})$";
	
	matchArray = [[lines objectAtIndex:lineNum++] arrayOfCaptureComponentsMatchedByRegex:regexStr];
	NSEnumerator *matchEnumerator = [[matchArray objectAtIndex:0] objectEnumerator];
	[matchEnumerator nextObject];
	// Constructing date.
	NSMutableString *date = [NSMutableString stringWithCapacity:10];
	for (int i = 0; i < 2; i++) {
		[date appendString:[matchEnumerator nextObject]];
		[date appendString:@"-"]; 
	}
	[date appendString:[matchEnumerator nextObject]];
	
	// Constructing time.
	NSMutableString *time = [NSMutableString stringWithCapacity:10];
	for (int i = 0; i < 2; i++) {
		[time appendString:[matchEnumerator nextObject]];
		[time appendString:@":"]; 
	}
	[time appendString:[matchEnumerator nextObject]];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm:ss"];
	// Finally, save date. 
	session.date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ at %@", date, time]];
	
	[self prepareImport];
	
	// Main loop.	
	// The next line must contains at least 2 columns.
	BOOL readyToEndBlock = NO;
	blockEndTime = 0;
	while(([currentLineFields = [[lines objectAtIndex:lineNum++] componentsSeparatedByString:@"\t"] 
			count] > 1) && lineNum < [lines count])
	{
		if (readyToEndBlock && [[currentLineFields objectAtIndex:0] intValue] > blockEndTime+1) {
			[self endBlock];
			readyToEndBlock = NO;
		}
		NSString *eventType = [currentLineFields objectAtIndex:1];
		if ([eventType isEqualToString:@"EyeGaze"]) {
			[self importGaze];
		} else if([eventType isEqualToString:@"Comment"]) {
			NSString *commentType = [currentLineFields objectAtIndex:2];
			if ([commentType isEqualToString:@"wave_start"]) {				
				[self startBlock];
			} else if ([commentType isEqualToString:@"wave_end"]) {
				if (!readyToEndBlock) {
					blockEndTime = [[currentLineFields objectAtIndex:0] intValue];
					readyToEndBlock = YES;
				}
			} else {
				[self parseFailureForType:@"comment type" unparsed:commentType];
			}
		} else if ([eventType isEqualToString:@"BlipAppeared"]) {			
			[self startTrial];
		} else if ([eventType isEqualToString:@"BlipMoved"]) {
			[self parseBlipMoved];
		} else if ([eventType isEqualToString:@"BlipChangedColor"]) {
			[self parseBlipChangedColor];
		} else if ([eventType isEqualToString:@"BlipDisappeared"]) {
			[self parseBlipDisappeared];
		} else if ([eventType isEqualToString:@"TrialData"]) {
			[self endTrial];
		} else if ([eventType isEqualToString:@"Keyboard"]) {
			[self parseKeyEvent];
		} else if ([eventType isEqualToString:@"Sound"]) {
			continue;
		} else if ([eventType isEqualToString:@"TrackingError"]) {
			continue;
		} else {
			[self parseFailureForType:@"event type" unparsed:eventType];
		}
	}
	
	[self consolidateGazesToIndex:[ongoingGazes count] - 1];
	NSLog(@"Discarded %d gaze samples.", discardedGazeCount);
	
	// Import completed. Save.
	[self saveData];
}

- (void)saveData
{
	NSError *error = nil;
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
	
	NSMutableArray * tempTrackNumConditions = [NSMutableArray arrayWithCapacity:9];
	for (int i =  1; i <= 9; i++) {
		VFCondition *tempCondition = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" inManagedObjectContext:moc];
		tempCondition.factor = @"track number";
		tempCondition.level = [[NSNumber numberWithInt:i] stringValue];

		[tempTrackNumConditions addObject:tempCondition];
	}
	trackNumConditions = [NSArray arrayWithArray:tempTrackNumConditions];
	
	NSMutableArray *tempTemplates = [NSMutableArray arrayWithCapacity:15];
	for (int i = 0; i < 5; i++) {
		for (int j = 0; j < 3; j++) {
			VFVisualStimulusTemplate *aBlipTemplate = 
				[NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusTemplate" inManagedObjectContext:moc];
			
			aBlipTemplate.imageFilePath = [NSString stringWithFormat:@"img/%d-%d.png", i, j];
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
}

#pragma mark -
#pragma mark -------PARSE GAZE-------
- (void)importGaze
{
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
			[self consolidateGazesToIndex:[ongoingGazes count] - 2];
			// Record the new gaze sample.
			[ongoingGazes addObject:[self makeGazeSample]];
			lastGazeTimeStamp = startAccumulateTimeStamp;
		} else {
			consolidateState = 1;
		}
	}
}

- (void)consolidateGazesToIndex:(NSUInteger)index
{
	NSUInteger consolidateEndTimeStamp = [((VFGazeSample *)[ongoingGazes objectAtIndex:index]).time intValue];
	float timePerGaze = (float)(consolidateEndTimeStamp - startAccumulateTimeStamp) / (float)(index + 1);
	// Sample rate cannot be larger than 122. If so, use 8.2.
	if (timePerGaze < 8.2)
		timePerGaze = 8.2;
	// Assign time backwards.
	for (int i = index; i >= 0; i--) {
		int assignTime = consolidateEndTimeStamp - (NSUInteger) (timePerGaze * (index - i));
		if (assignTime <= startAccumulateTimeStamp || assignTime > [((VFGazeSample *)[ongoingGazes objectAtIndex:i]).time intValue]  + 10) {
			//NSLog(@"Discard the gaze sample of time stamp %d for it is less than %d", assignTime, startAccumulateTimeStamp);
			[moc deleteObject:[ongoingGazes objectAtIndex:i]];
			discardedGazeCount++;
		} else {
			((VFGazeSample *)[ongoingGazes objectAtIndex:i]).time = [NSNumber numberWithUnsignedInt:assignTime];
			[currentBlock addGazeSamplesObject:[ongoingGazes objectAtIndex:i]];
		}
	}
	
	[ongoingGazes removeObjectsInRange:NSMakeRange(0, index + 1)];
	// Consolidating finished.
	consolidateState = 0;
	startAccumulateTimeStamp = consolidateEndTimeStamp;
}

- (VFGazeSample *)makeGazeSample
{
	VFGazeSample *gaze = [NSEntityDescription insertNewObjectForEntityForName:@"GazeSample" inManagedObjectContext:moc];
	
	gaze.location = [self makeLocation];
	gaze.valid = [NSNumber numberWithBool:([[currentLineFields objectAtIndex:5] isEqualToString:@"1"]) ? YES : NO];
	gaze.time = [NSNumber numberWithUnsignedInt:[[currentLineFields objectAtIndex:0] intValue]];
	
	return gaze;
}
#pragma mark -
#pragma mark -------PARSE BLOCK-------
- (void)startBlock
{
	currentBlock = [NSEntityDescription insertNewObjectForEntityForName:@"Block" inManagedObjectContext:moc];	
	[session addBlocksObject:currentBlock];
	
	currentBlock.ID = [@"wave " stringByAppendingString:[currentLineFields objectAtIndex:3]];
	currentBlock.order = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:3] intValue]];
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
	} else {
		[self parseFailureForType:@"wave size" unparsed:waveSize];
	}
	
	NSString *waveType = [currentLineFields objectAtIndex:5];
	if ([waveType isEqualToString:@"ran"]) {
		[currentBlock addConditionsObject:waveTypeRandom];
	} else if ([waveType isEqualToString:@"pre"]) {
		[currentBlock addConditionsObject:waveTypePreclassifiable];
	} else {
		[self parseFailureForType:@"wave type" unparsed:waveType];
	}
}

- (void)endBlock
{
	currentBlock.endTime = [NSNumber numberWithInt:blockEndTime];
	
	// Consolidate ongoing gaze samples.
	[self consolidateGazesToIndex:[ongoingGazes count] - 1];
	
	currentBlock = nil;
	[self saveData];
}

#pragma mark -
#pragma mark -------PARSE TRIAL AND SUBTRIAL-------
- (void)startTrial
{
	VFTrial *trial = [NSEntityDescription insertNewObjectForEntityForName:@"Trial" inManagedObjectContext:moc];
	[currentBlock addTrialsObject:trial];
	trial.ID = [@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]];
	trial.order = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:2] intValue]];
	trial.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];

	[ongoingTrials setObject:trial forKey:trial.ID];
	
	NSString *blipType = [currentLineFields objectAtIndex:5];
	if ([blipType isEqualToString:@"1"]) {
		[trial addConditionsObject:blipTypeFighter];
	} else if ([blipType isEqualToString:@"2"]) {
		[trial addConditionsObject:blipTypeSupport];
	} else if ([blipType isEqualToString:@"3"]) {
		[trial addConditionsObject:blipTypeMissile];
	} else {
		[self parseFailureForType:@"blip type" unparsed:blipType];
	}
	
	NSString *blipDesignation = [currentLineFields objectAtIndex:6];
	if ([blipDesignation isEqualToString:@"1"]) {
		[trial addConditionsObject:blipDesignationNeutral];
	} else if ([blipDesignation isEqualToString:@"2"]) {
		[trial addConditionsObject:blipDesignationHostile];
	} else {
		[self parseFailureForType:@"blip designation" unparsed:blipDesignation];
	}
	
	VFCondition *trackNumCondition = [trackNumConditions objectAtIndex:[[currentLineFields objectAtIndex:10] intValue] - 1];
	[trial addConditionsObject:trackNumCondition];
	
	NSString *blipSensor = [currentLineFields objectAtIndex:7];
	if ([blipSensor isEqualToString:@"1"]) {
		[trial addConditionsObject:blipSensorFail];
	} else if ([blipSensor isEqualToString:@"0"]) {
		[trial addConditionsObject:blipSensorNotFail];
	} else {
		[self parseFailureForType:@"blip sensor" unparsed:blipSensor];
	}
	
	// Parse subTrial.
	VFSubTrial *subTrial = [NSEntityDescription insertNewObjectForEntityForName:@"SubTrial" inManagedObjectContext:moc];
	subTrial.ID = @"PreClassify";
	subTrial.startTime = trial.startTime;
	[trial addSubTrialsObject:subTrial];
	
	// Parse screen object.
	VFVisualStimulus *blip = [self makeBlip];
	blip.label = [currentLineFields objectAtIndex:10];
	// Black blip.
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

	VFTrial *trial = [ongoingTrials objectForKey:[@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]]];
	
	// Start new subTrial
	VFSubTrial *subTrial = [NSEntityDescription insertNewObjectForEntityForName:@"SubTrial" inManagedObjectContext:moc];
	if (![[currentLineFields objectAtIndex:6] isEqualToString:@"5"]) // It's not changing to white.
	{
		// Add target stimulus.
		[trial addTargetVisualStimuliObject:newBlip];
		
		subTrial.ID = @"InClassify";
	} else {
		subTrial.ID = @"PostClassify";
	}
	subTrial.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	// Add it to trial's subTrials list.
	[trial addSubTrialsObject:subTrial];
}


- (void)parseBlipDisappeared
{
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[currentLineFields objectAtIndex:2]];
	// End blip frame.
	[self endBlipFrameForBlip:blip];
	// End blip.
	blip.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
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

#pragma mark -
#pragma mark ------PARSE OTHER EVENTS-------
- (void)parseKeyEvent
{
	VFKeyboardEvent *keyEvent = [NSEntityDescription insertNewObjectForEntityForName:@"KeyboardEvent" inManagedObjectContext:moc];
	keyEvent.key = [currentLineFields objectAtIndex:2];
	NSString *keyCategory = [currentLineFields objectAtIndex:3];
	if ([keyCategory isEqualToString:@"1"]) {
		keyEvent.category = @"first key";
	} else if ([keyCategory isEqualToString:@"2"]) {
		keyEvent.category = @"second key";
	} else {
		[self parseFailureForType:@"key category" unparsed:keyCategory];
	}
	keyEvent.time = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	[currentBlock addKeyboardEventsObject:keyEvent];
}

- (void)parseSound
{
	// TODO: Incomplete.
	VFAuditoryStimulus *sound = [NSEntityDescription insertNewObjectForEntityForName:@"AuditoryStimulus" inManagedObjectContext:moc];
	sound.location = [self makeLocation];
}

#pragma mark -
#pragma mark ------HELPER METHODS-------
- (NSPoint)makeLocation 
{
	// The output blip location indicates the position of the blip icon's left-top corner.
	NSPoint location;
	
	location.x = [[currentLineFields objectAtIndex:3] floatValue];
	location.y = [[currentLineFields objectAtIndex:4] floatValue];
	
	return location;
}

- (void)parseFailureForType:(NSString *)failureType unparsed:(NSString *)unparsedString
{
	NSLog(@"Parsing %@ failed. The unparsed string is: %@.\n%@", failureType, unparsedString, [lines objectAtIndex:lineNum - 1]);
}
@end
