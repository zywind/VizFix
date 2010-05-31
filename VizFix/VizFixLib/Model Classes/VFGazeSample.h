//
//  VFGazeSample.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface VFGazeSample :  NSManagedObject  
{
	NSPoint location;
}

@property (nonatomic, assign) NSPoint location;
@property (nonatomic, retain) NSNumber * valid;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSNumber * pupilDiameter;
@property (nonatomic, retain) NSNumber * focusRange;
@property (nonatomic, retain) NSNumber * xEyeOffset;
@property (nonatomic, retain) NSNumber * yEyeOffset;

@property (nonatomic, retain) NSString * locationAsString;
@property (nonatomic, assign) NSPoint primitiveLocation;

@end