//
//  VFDualTaskImport.h
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 1/14/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFCondition.h"
#import "VFBlock.h"
#import "VFSession.h"
#import "VFCondition.h"
#import "VFGazeSample.h"
#import "VFTrial.h"
#import "VFSubTrial.h"
#import "VFResponse.h"
#import "VFVisualStimulus.h"
#import "VFVisualStimulusFrame.h"
#import "VFVisualStimulusTemplate.h"
#import "VFKeyboardEvent.h"
#import "VFAuditoryStimulus.h"
#import "VFDTFixationAlg.h"

#import "RegexKitLite.h"

@interface VFDualTaskImport : NSObject {
	NSManagedObjectContext *moc;
	
	NSArray *lines;	
	NSUInteger lineNum;
	NSArray *currentLineFields;
	
	VFCondition *soundCondition;
	VFCondition *gazeCondition;	
	VFCondition *waveSizeOne;
	VFCondition *waveSizeTwo;
	VFCondition *waveSizeFour;
	VFCondition *waveSizeSix;
	VFCondition *waveSizeEight;
	VFCondition *waveTypeRandom;
	VFCondition *waveTypePreclassifiable;
	VFCondition *blipTypeFighter;
	VFCondition *blipTypeSupport;
	VFCondition *blipTypeMissile;
	VFCondition *blipDesignationNeutral;
	VFCondition *blipDesignationHostile;
	VFCondition *blipSensorFail;
	VFCondition *blipSensorNotFail;
	NSArray *blipColorCodes;
	NSArray *trackNumConditions;
	
	NSArray *visualStimuliTemplates;
	
	VFSession *session;
	VFBlock *currentBlock;
	NSMutableDictionary *ongoingBlips;
	NSMutableDictionary *ongoingTrials;
	NSMutableArray *ongoingGazes;
	
	int discardedGazeCount;
	int lastGazeTimeStamp;
	int startAccumulateTimeStamp;
	int consolidateState;
	
	NSUInteger blockEndTime;
}

@property (nonatomic, retain) NSManagedObjectContext * moc;
@property NSUInteger lineNum;

- (VFDualTaskImport *)initWithMOC:(NSManagedObjectContext *)anMOC;
- (void)import:(NSURL *)rawDataFileURL;
- (void)prepareImport;
- (void)saveData;

- (void)importGaze;
- (void)consolidateGazesToIndex:(NSUInteger)index;

- (void)startBlock;
- (void)endBlock;
- (void)startTrial;
- (void)endTrial;
- (void)parseBlipMoved;
- (void)parseBlipChangedColor;
- (void)parseBlipDisappeared;
- (NSString *)getBlipStatus;
- (NSString *)getBlipID;
- (NSString *)getLastBlipID;
- (void)parseKeyEvent;
- (void)parseSound;
- (void)parseFailureForType:(NSString *)failureType unparsed:(NSString *)unparsedString;

- (VFVisualStimulusFrame *)makeBlipFrame;
- (void)endBlipFrameForBlip:(VFVisualStimulus *)vs;
- (NSPoint)makeLocation;
- (void)endLastSubTrial;
- (VFGazeSample *)makeGazeSample;
- (VFVisualStimulus *)makeBlip;
@end
