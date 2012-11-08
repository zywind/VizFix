/********************************************************************
 File:   VFFixation.h
 
 Created:  1/22/10
 Modified: 7/15/10
 
 Author: Yunfeng Zhang
 Cognitive Modeling and Eye Tracking Lab
 CIS Department
 University of Oregon
 
 Funded by the Office of Naval Research & National Science Foundation.
 Primary Investigator: Anthony Hornof.
 
 Copyright (c) 2010 by the University of Oregon.
 ALL RIGHTS RESERVED.
 
 Permission to use, copy, and distribute this software in
 its entirety for non-commercial purposes and without fee,
 is hereby granted, provided that the above copyright notice
 and this permission notice appear in all copies and their
 documentation.
 
 Software developers, consultants, or anyone else who wishes
 to use all or part of the software or its documentation for
 commercial purposes should contact the Technology Transfer
 Office at the University of Oregon to arrange a commercial
 license agreement.
 
 This software is provided "as is" without expressed or
 implied warranty of any kind.
 ********************************************************************/

#import <CoreData/CoreData.h>
@class VFVisualStimulusFrame;

@interface VFFixation :  NSManagedObject  
{
	NSPoint location;
}

@property (nonatomic, assign) NSPoint location;
@property (nonatomic, assign) NSPoint primitiveLocation;
@property (nonatomic, strong) NSString * locationAsString;
@property (nonatomic, strong) NSNumber * startTime;
@property (nonatomic, strong) NSNumber * endTime;
@property (nonatomic, strong) VFVisualStimulusFrame * fixatedStimulus;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) VFFixation *relatedFixation;

@end



