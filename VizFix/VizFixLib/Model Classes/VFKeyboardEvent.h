//
//  VFKeyboardEvent.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface VFKeyboardEvent :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * key;

@end



