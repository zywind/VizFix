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

- (id)initWithMOC:(NSManagedObjectContext *)anMOC
{	
	if (self = [super init]) {
		moc = anMOC;
		blipColorCodes = [NSArray arrayWithObjects:@"0", @"1", @"2", @"5", @"7", nil];
		
		percentFormatter = [[NSNumberFormatter alloc] init];
		[percentFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[percentFormatter setNumberStyle:NSNumberFormatterPercentStyle];
		
		decimalFormatter = [[NSNumberFormatter alloc] init];
		[decimalFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[decimalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[decimalFormatter setMaximumFractionDigits:2];
		
		sciFormatter = [[NSNumberFormatter alloc] init];
		[sciFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[sciFormatter setNumberStyle:NSNumberFormatterScientificStyle];
		[sciFormatter setPositivePrefix:@"+"];
		
		allDrivingFunctions = nil;
    }
    return self;
}

- (void)reset
{
	lines = nil;
	lineNum = 0;
	currentLineFields = nil;
	
	discardedGazeCount = 0;
	lastGazeTimeStamp = 0;
	startAccumulateTimeStamp = 0;
	consolidateState = 0;
	blockEndTime = 0;
	numValidGazes = 0;
	numInvalidGazes = 0;
	numTrackingEvent = 0;
	pauseOn = NO;
	
	// Initialize temporary containers.
	session = nil;
	currentBlock = nil;
	ongoingBlips = [NSMutableDictionary dictionaryWithCapacity:10];
	ongoingTrials = [NSMutableDictionary dictionaryWithCapacity:10];
	ongoingGazes = [NSMutableArray arrayWithCapacity:10];
	ongoingTEs = [NSMutableArray arrayWithCapacity:10];
}

- (void)import:(NSURL *)rawDataFileURL
{
	[self reset];
	
	if (allDrivingFunctions == nil) {
		NSURL *dfURL = [NSURL fileURLWithPath:[[[rawDataFileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"driving_function3"]];
		
		NSString *dfContents = 	[NSString stringWithContentsOfURL:dfURL encoding:NSUTF8StringEncoding error:NULL];
		allDrivingFunctions = [NSMutableArray arrayWithCapacity:22000];
		
		int i = 0;
		for (NSString *eachLine in [dfContents componentsSeparatedByString:@"\n"]) {
			i++;
			// Record only the easy one.
			if (i % 4 == 3 || i % 4 == 0) {
				[allDrivingFunctions addObject:[sciFormatter numberFromString:eachLine]];
			}
		}
	}
	
	NSLog(@"Starting to import file %@.", [rawDataFileURL path]);
	
	session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:moc];
	session.distanceToScreen = [NSNumber numberWithInt:610]; // in mm.
	session.screenResolution = NSMakeSize(1280.0, 1024.0); // in pixel.
	session.experiment = @"NRL Dual Task";
	session.gazeSampleRate = [NSNumber numberWithInt:120]; // per second.
	session.screenDimension = NSMakeSize(432.0, 407.0); // in mm. Taken from http://www.aurora.se/neovo/neovo-x174.htm .
	VFVisualStimulusTemplate *backgroundTemplate = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusTemplate"
																				 inManagedObjectContext:moc];
	backgroundTemplate.imageFilePath = @"img/background.png";
	backgroundTemplate.category = @"background";
	backgroundTemplate.outline = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 1280, 1024)];
	
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
	
	NSError *error;
	// Read raw data file.	
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
	while(([currentLineFields = [[lines objectAtIndex:lineNum++] componentsSeparatedByString:@"\t"] 
			count] > 1) && lineNum < [lines count])
	{
		// Sometimes wave end comment appears before a blip disppears. So we delay the end time by
		// 5 ms.
		if (readyToEndBlock && [[currentLineFields objectAtIndex:0] intValue] > blockEndTime + 5) {
			[self endBlock];
			readyToEndBlock = NO;
			if (pauseOn) {
				[self parsePauseBlock];
			}
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
			} else if ([commentType isEqualToString:@"pause"]) {
				pauseOn = YES;
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
			[self parseTrackingError];
		} else if ([eventType isEqualToString:@"ScenarioFile"]
				   || [eventType isEqualToString:@"ScreenResolution"]
				   || [eventType isEqualToString:@"GazeContingent"]
				   || [eventType isEqualToString:@"Tracking payment"]
				   || [eventType isEqualToString:@"Tactical payment"]
				   || [eventType isEqualToString:@"AdditionalErrorData"]
				   || [eventType isEqualToString:@"ClassifyData"]) {
			continue;
			
		} else {
			[self parseFailureForType:@"event type" unparsed:eventType];
		}
	}
	
	[self consolidateGazesToIndex:[ongoingGazes count] - 1];
	session.duration = [NSNumber numberWithInt:startAccumulateTimeStamp];
	
	NSLog(@"Discarded %d gaze samples.", discardedGazeCount);
	// Import completed. Save.
	[self saveData];
	NSLog(@"Import file %@ succeeded.", [rawDataFileURL path]);
	
	NSLog(@"Start to detect fixations.");
	VFDTFixationAlg *fixationDetectionAlg = [[VFDTFixationAlg alloc] init];
	[fixationDetectionAlg detectAllFixationsInMOC:moc withRadiusThresholdInDOV:0.7];
	[self saveData];
	NSLog(@"Detecting fixations succeeded.");
	
	NSLog(@"Start to register fixations to AOIs.");
	// Register fixations to AOIs.
	NSBezierPath *radarAOI = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 180, 710, 512)];
	NSBezierPath *trackingAOI = [NSBezierPath bezierPathWithRect:NSMakeRect(740, 242, 540, 540)];
	NSDictionary *customAOIs = [NSDictionary dictionaryWithObjectsAndKeys:radarAOI, @"Radar Display", 
								trackingAOI, @"Tracking Display", nil];
	
	VFFixationRegister *fixRegister = [[VFFixationRegister alloc] initWithMOC:moc];
	fixRegister.autoAOIDOV = 2.5;
	fixRegister.customAOIs = customAOIs;
	[fixRegister registerAllFixations];

	[self saveData];
	NSLog(@"Registering fixations completed.\nImport completed.\n\n");
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
			aBlipTemplate.outline = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 32, 32)];
			
			[tempTemplates addObject:aBlipTemplate];
		}
	}
	
	blipTemplates = [NSArray arrayWithArray:tempTemplates];
	
	trackingTarget = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulus" 
												   inManagedObjectContext:moc];
	
	trackingTarget.startTime = [NSNumber numberWithInt:0];
	trackingTarget.ID = "tracking target";
	VFVisualStimulusTemplate *trackingTemplate = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusTemplate" 
																			   inManagedObjectContext:moc];
	trackingTemplate.outline = [NSBezierPath bezierPathWithRect:NSRect(0, 0, 32, 32)];
	trackingTemplate.category = @"tracking target";
	trackingTemplate.color = [NSColor blackColor];
	trackingTarget.template = trackingTemplate;
	lastTrackingTargetFrame = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusFrame" 
															inManagedObjectContext:moc];
	lastTrackingTargetFrame.location = NSMakePoint(1010, 512);
	lastTrackingTargetFrame.startTime = 0;
	[trackingTarget addFramesObject:lastTrackingTargetFrame];
	
	trackingCursor = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulus" 
												   inManagedObjectContext:moc];
	
	trackingCursor.startTime = [NSNumber numberWithInt:0];
	trackingCursor.ID = "tracking cursor";
	VFVisualStimulusTemplate *trackingTemplate = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusTemplate" 
																			   inManagedObjectContext:moc];
	trackingTemplate.outline = [NSBezierPath bezierPathWithOvalInRect:NSRect(0, 0, 32, 32)];
	trackingTemplate.category = @"tracking cursor";
	trackingTemplate.color = [NSColor blackColor];
	trackingCursor.template = trackingTemplate;
	lastTrackingCursorFrame = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusFrame" 
															inManagedObjectContext:moc];
	lastTrackingCursorFrame.location = NSMakePoint(1010, 512);
	lastTrackingCursorFrame.startTime = 0;
	[trackingCursor addFramesObject:lastTrackingCursorFrame];
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
		VFGazeSample *currentGaze = [ongoingGazes objectAtIndex:i];
		if (assignTime <= startAccumulateTimeStamp || assignTime > [currentGaze.time intValue]  + 10) {
			//NSLog(@"Discard the gaze sample of time stamp %d for it is less than %d", assignTime, startAccumulateTimeStamp);
			if ([currentGaze.valid boolValue])
				numValidGazes--;
			else
				numInvalidGazes--;
			[moc deleteObject:currentGaze];
			discardedGazeCount++;
		} else {
			currentGaze.time = [NSNumber numberWithUnsignedInt:assignTime];
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
	
	if ([gaze.valid boolValue])
		numValidGazes++;
	else
		numInvalidGazes++;
	
	return gaze;
}
#pragma mark -
#pragma mark -------PARSE BLOCK-------
- (void)startBlock
{
	if (pauseOn) {
		currentBlock.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
		VFTrial *pauseTrial = [currentBlock.trials anyObject];
		pauseTrial.endTime = currentBlock.endTime;
		VFSubTrial *subTrial = [pauseTrial.subTrials anyObject];
		subTrial.endTime = currentBlock.endTime;
		pauseOn = NO;
		
		VFCondition *RMSTrackingError = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" 
																	  inManagedObjectContext:moc];
		RMSTrackingError.factor = @"RMS Tracking Error";
		RMSTrackingError.level = [decimalFormatter stringFromNumber:[NSNumber numberWithDouble:[self calculateRMSTRackingError]]];
		[currentBlock addConditionsObject:RMSTrackingError];
		[ongoingTEs removeAllObjects];
	}
	currentBlock = [NSEntityDescription insertNewObjectForEntityForName:@"Block" inManagedObjectContext:moc];	
	[session addBlocksObject:currentBlock];
	
	currentBlock.ID = [@"wave " stringByAppendingString:[currentLineFields objectAtIndex:3]];
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
	currentBlock.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
	
	// Consolidate ongoing gaze samples.
	[self consolidateGazesToIndex:[ongoingGazes count] - 1];
	
	VFCondition *validGazeRate = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" 
															   inManagedObjectContext:moc];
	validGazeRate.factor = @"valid gaze rate";
	validGazeRate.level = [percentFormatter stringFromNumber:
						   [NSNumber numberWithFloat:(float)numValidGazes / (float)(numValidGazes+numInvalidGazes)]];
	[currentBlock addConditionsObject:validGazeRate];
	
	VFCondition *RMSTrackingError = [NSEntityDescription insertNewObjectForEntityForName:@"Condition" 
																  inManagedObjectContext:moc];
	RMSTrackingError.factor = @"RMS Tracking Error";
	RMSTrackingError.level = [decimalFormatter stringFromNumber:[NSNumber numberWithDouble:[self calculateRMSTRackingError]]];
	[currentBlock addConditionsObject:RMSTrackingError];
	[ongoingTEs removeAllObjects];
	
	numValidGazes = 0;
	numInvalidGazes = 0;	
	currentBlock = nil;
	[self saveData];
}

- (void)parsePauseBlock
{
	currentBlock = [NSEntityDescription insertNewObjectForEntityForName:@"Block" inManagedObjectContext:moc];	
	[session addBlocksObject:currentBlock];
	
	currentBlock.ID = @"pause";
	currentBlock.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	
	[currentBlock addConditionsObject:gazeCondition];
	[currentBlock addConditionsObject:soundCondition];
	
	VFTrial *pauseTrial = [NSEntityDescription insertNewObjectForEntityForName:@"Trial" inManagedObjectContext:moc];
	pauseTrial.ID = @"pause";
	pauseTrial.startTime = currentBlock.startTime;
	[currentBlock addTrialsObject:pauseTrial];
	
	VFSubTrial *subTrial = [NSEntityDescription insertNewObjectForEntityForName:@"SubTrial" inManagedObjectContext:moc];
	subTrial.ID = @"pause";
	subTrial.startTime = currentBlock.startTime;
	[pauseTrial addSubTrialsObject:subTrial];
}

#pragma mark -
#pragma mark -------PARSE TRIAL AND SUBTRIAL-------
- (void)startTrial
{
	VFTrial *trial = [NSEntityDescription insertNewObjectForEntityForName:@"Trial" inManagedObjectContext:moc];

	[currentBlock addTrialsObject:trial];
	trial.ID = [@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]];
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
	VFVisualStimulus *blip = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulus" 
														   inManagedObjectContext:moc];
	blip.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	blip.ID = [[currentLineFields objectAtIndex:2] stringByAppendingString:@" PreClassify"];
	blip.label = [currentLineFields objectAtIndex:10];
	// Black blip.
	blip.template = [blipTemplates objectAtIndex:[[currentLineFields objectAtIndex:5] intValue] - 1];
	
	[ongoingBlips setObject:blip forKey:blip.ID];
	
	[blip addFramesObject:[self makeBlipFrame]];
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
	// Sometimes a BlipMoved message for a new color appears before BlipChangeColor message.
	// If so, ignore this frame.
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[self getBlipID]];
	if (blip != nil) {
		[self endBlipFrameForBlip:blip];
		[blip addFramesObject:[self makeBlipFrame]];
	}
}

- (void)parseBlipChangedColor
{
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[self getLastBlipID]];
	[self endBlipFrameForBlip:blip];
	blip.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
	[ongoingBlips removeObjectForKey:blip.ID];
	
	int colorIndex = [blipColorCodes indexOfObject:[currentLineFields objectAtIndex:6]];
	int typeIndex = [[currentLineFields objectAtIndex:5] intValue] - 1;
	
	VFVisualStimulus *newBlip = [self makeBlip];
	newBlip.template = [blipTemplates objectAtIndex:(colorIndex * 3 + typeIndex)];
	[newBlip addFramesObject:[self makeBlipFrame]];
	[ongoingBlips setObject:newBlip forKey:newBlip.ID];
	
	// End last subTrial.
	[self endLastSubTrial];

	VFTrial *trial = [ongoingTrials objectForKey:[@"blip " stringByAppendingString:[currentLineFields objectAtIndex:2]]];
	
	// Start new subTrial
	VFSubTrial *subTrial = [NSEntityDescription insertNewObjectForEntityForName:@"SubTrial" inManagedObjectContext:moc];
		
	subTrial.ID = [self getBlipStatus];
	
	subTrial.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	// Add it to trial's subTrials list.
	[trial addSubTrialsObject:subTrial];
}


- (void)parseBlipDisappeared
{
	VFVisualStimulus *blip = [ongoingBlips objectForKey:[self getBlipID]];
	// End blip frame.
	[self endBlipFrameForBlip:blip];
	// End blip.
	blip.endTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue] - 1];
}

- (VFVisualStimulus *)makeBlip
{
	VFVisualStimulus *blip = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulus" 
														   inManagedObjectContext:moc];
	blip.startTime = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	blip.label = [currentLineFields objectAtIndex:7];
	blip.ID = [self getBlipID];
		
	return blip;
}

- (NSString *)getBlipStatus
{
	NSString *blipColor = [currentLineFields objectAtIndex:6];
	if ([blipColor isEqualToString:@"0"])
		return @"PreClassify";
	else if ([blipColor isEqualToString:@"5"])
		return @"PostClassify";
	else if ([blipColor isEqualToString:@"1"]
			 || [blipColor isEqualToString:@"2"]
			 || [blipColor isEqualToString:@"7"])
		return @"InClassify";
	else {
		[self parseFailureForType:@"Unexpected blip color." unparsed:blipColor];
		return nil;
	}
}

- (NSString *)getBlipID
{
	NSString *ID = [currentLineFields objectAtIndex:2];
	NSString *status = [self getBlipStatus];	
	
	return [NSString stringWithFormat:@"%@ %@", ID, status];
}

- (NSString *)getLastBlipID
{
	NSString *ID = [currentLineFields objectAtIndex:2];
	NSString *status = nil;
	NSString *blipColor = [currentLineFields objectAtIndex:6];
	if ([blipColor isEqualToString:@"5"])
		status = @"InClassify";
	else if ([blipColor isEqualToString:@"1"]
			 || [blipColor isEqualToString:@"2"]
			 || [blipColor isEqualToString:@"7"])
		status = @"PreClassify";
	else
		[self parseFailureForType:@"Unexpected blip color." unparsed:blipColor];
	
	return [NSString stringWithFormat:@"%@ %@", ID, status];
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
}

- (void)parseTrackingError
{
	VFCustomEvent *trackingEvent = [NSEntityDescription insertNewObjectForEntityForName:@"CustomEvent" inManagedObjectContext:moc];
	trackingEvent.category = @"tracking error";
	trackingEvent.desc = [currentLineFields objectAtIndex:4];
	trackingEvent.time = [NSNumber numberWithInt:[[currentLineFields objectAtIndex:0] intValue]];
	
	VFVisualStimulusFrame *trackingFrame = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusFrame" inManagedObjectContext:moc];
	trackingFrame.location = 
	
	trackingTarget.
	
	numTrackingEvent++;
	if (currentBlock != nil) {
		[ongoingTEs addObject:trackingEvent];
	}
}

- (double)calculateRMSTRackingError
{
	double sumOfSquares = 0;
	for (VFCustomEvent *eachTE in ongoingTEs) {
		double te = [eachTE.desc doubleValue];
		sumOfSquares += te * te;
	}
	return sqrt(sumOfSquares / [ongoingTEs count]);
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
