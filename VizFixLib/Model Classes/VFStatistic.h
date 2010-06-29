//
//  VFResponse.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>

@class VFProcedure;

/**
 Stores statistics of a procedure.
 */
@interface VFStatistic :  NSManagedObject  
{
}

/**
 The measure name.￼
 */
@property (nonatomic, retain) NSString * measure;
/**
 The value in string.￼
 */
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) VFProcedure * ofTrial;

@end



