//
//  VFSubTrial.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFTrial;

@interface VFSubTrial :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSString * ID;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) VFTrial * inTrial;
@property (nonatomic, readonly) BOOL leaf;
@property (nonatomic, readonly) NSSet* children;

@end



