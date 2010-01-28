//
//  VFAuditoryStimulus.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFAudioSource;
@class VFTrial;

@interface VFAuditoryStimulus :  NSManagedObject  
{
	NSPoint location;
}

@property (nonatomic, assign) NSPoint location;
@property (nonatomic, assign) NSPoint primitiveLocation;
@property (nonatomic, retain) NSString * locationAsString;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) VFAudioSource * audioSource;
@property (nonatomic, retain) VFTrial * isTargetOfTrial;

@end


