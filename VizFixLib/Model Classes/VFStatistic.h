//
//  VFResponse.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFProcedure;

@interface VFStatistic :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * measure;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) VFProcedure * ofTrial;

@end



