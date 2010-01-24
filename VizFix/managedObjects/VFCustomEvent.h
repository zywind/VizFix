//
//  VFCustomEvent.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface VFCustomEvent :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * category;

@end



