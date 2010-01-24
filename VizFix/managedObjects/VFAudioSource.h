//
//  VFAudioSource.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "VFAuditoryStimulus.h"

@interface VFAudioSource :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * audioFilePath;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSSet* ofAuditoryStimuli;

@end

@interface VFAudioSource (CoreDataGeneratedAccessors)
- (void)addOfAuditoryStimuliObject:(VFAuditoryStimulus *)value;
- (void)removeOfAuditoryStimuliObject:(VFAuditoryStimulus *)value;
- (void)addOfAuditoryStimuli:(NSSet *)value;
- (void)removeOfAuditoryStimuli:(NSSet *)value;

@end



