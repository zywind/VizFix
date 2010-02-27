//
//  VFAuditoryStimulus.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFAudioSource;

@interface VFAuditoryStimulus :  NSManagedObject  
{
	NSPoint location;
}

@property (nonatomic, assign) NSPoint location;
@property (nonatomic, assign) NSPoint primitiveLocation;
@property (nonatomic, retain) NSString * locationAsString;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, readonly) NSNumber * endTime;
@property (nonatomic, retain) VFAudioSource * audioSource;

@end



