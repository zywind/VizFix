//
//  VFVisualStimulusFrame.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFVisualStimulus;

@interface VFVisualStimulusFrame :  NSManagedObject  
{
	NSPoint location;
}

@property (nonatomic, assign) NSPoint location;
@property (nonatomic, assign) NSPoint primitiveLocation;
@property (nonatomic, retain) NSString * locationAsString;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) VFVisualStimulus * ofVisualStimulus;

@end



