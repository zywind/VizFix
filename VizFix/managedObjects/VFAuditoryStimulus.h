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
}

@property (nonatomic, retain) NSNumber * x;
@property (nonatomic, retain) NSNumber * y;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSNumber * z;
@property (nonatomic, retain) VFAudioSource * audioSource;
@property (nonatomic, retain) VFTrial * isTargetOfTrial;

@end



